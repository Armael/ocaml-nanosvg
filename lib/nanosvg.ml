type image_raw
type image = { mutable raw : image_raw option }
let image_get img =
  match img.raw with
  | None -> raise (Invalid_argument "Nanosvg: image has been deleted")
  | Some raw -> raw

external image_delete_ : image_raw -> unit = "caml_nsvg_delete" [@@noalloc]
let image_delete img =
  let raw = image_get img in
  img.raw <- None;
  image_delete_ raw

let mk_image raw =
  let img = { raw = Some raw } in
  Gc.finalise image_delete img; img

type shape_raw
type shape = { raw : shape_raw; owner : image }
let shape_get s =
  match s.owner.raw with
  | None -> raise (Invalid_argument "Nanosvg: using a shape from a deleted image")
  | Some _ -> s.raw

module Image = struct
  type t = image
  let delete = image_delete

  external width_ : image_raw -> float = "caml_nsvg_image_width"
  external height_ : image_raw -> float = "caml_nsvg_image_height"
  let width img = width_ (image_get img)
  let height img = height_ (image_get img)

  external shapes_ : image_raw -> shape_raw list = "caml_nsvg_image_shapes"
  let shapes (img : image) : shape list =
    List.map (fun raw -> { raw; owner = img }) (shapes_ (image_get img))
end

type line_join = Join_miter | Join_round | Join_bevel
type line_cap = Cap_butt | Cap_round | Cap_square
type fill_rule = Fillrule_nonzero | Fillrule_evenodd
(* Values of these types are constructed from C. Constructors integer
   representations MUST match the enum numbers from C *)

module Gradient = struct
  type raw
  type t = { raw : raw; owner : image }
  let _get g =
    match g.owner.raw with
    | None -> raise (Invalid_argument "Nanosvg: using a gradient from a deleted image")
    | Some _ -> g.raw
  let mk img raw =
    { raw; owner = img }
end

[@@@ocaml.warning "-37"]
type paint_raw =
  | Paint_none
  | Paint_color of Int32.t
  | Paint_linear_gradient of Gradient.raw
  | Paint_radial_gradient of Gradient.raw
(* values of this type are constructed from C *)

type paint =
  | Paint_none
  | Paint_color of Int32.t
  | Paint_linear_gradient of Gradient.t
  | Paint_radial_gradient of Gradient.t

let mk_paint img (p : paint_raw) : paint =
  match p with
  | Paint_none -> Paint_none
  | Paint_color i -> Paint_color i
  | Paint_linear_gradient g -> Paint_linear_gradient (Gradient.mk img g)
  | Paint_radial_gradient g -> Paint_radial_gradient (Gradient.mk img g)

module Shape = struct
  type t = shape

  external fill_ : shape_raw -> paint_raw = "caml_nsvg_shape_fill"
  let fill s = mk_paint s.owner (fill_ (shape_get s))
  external stroke_ : shape_raw -> paint_raw = "caml_nsvg_shape_stroke"
  let stroke s = mk_paint s.owner (stroke_ (shape_get s))
  external opacity_ : shape_raw -> float = "caml_nsvg_shape_opacity"
  let opacity s = opacity_ (shape_get s)
  external stroke_width_ : shape_raw -> float = "caml_nsvg_shape_stroke_width"
  let stroke_width s = stroke_width_ (shape_get s)
  external stroke_dash_offset_ : shape_raw -> float = "caml_nsvg_shape_stroke_dash_offset"
  let stroke_dash_offset s = stroke_dash_offset_ (shape_get s)
  external stroke_dash_count_ : shape_raw -> int = "caml_nsvg_shape_stroke_dash_count" [@@noalloc]
  let stroke_dash_count s = stroke_dash_count_ (shape_get s)
  external stroke_line_join_ : shape_raw -> line_join = "caml_nsvg_shape_stroke_line_join" [@@noalloc]
  let stroke_line_join s = stroke_line_join_ (shape_get s)
  external stroke_line_cap_ : shape_raw -> line_cap = "caml_nsvg_shape_stroke_line_cap" [@@noalloc]
  let stroke_line_cap s = stroke_line_cap_ (shape_get s)
  external miter_limit_ : shape_raw -> float = "caml_nsvg_shape_miter_limit"
  let miter_limit s = miter_limit_ (shape_get s)
  external fill_rule_ : shape_raw -> fill_rule = "caml_nsvg_shape_fill_rule" [@@noalloc]
  let fill_rule s = fill_rule_ (shape_get s)
end

type units = Px | Pt | Pc | Mm | Cm | In

let string_of_units = function
  | Px -> "px"
  | Pt -> "pt"
  | Pc -> "pc"
  | Mm -> "mm"
  | Cm -> "cm"
  | In -> "in"

external parse_from_file_ : string -> string -> float -> image_raw option =
  "caml_nsvg_parse_from_file"

let parse_from_file ?(units = Px) ?(dpi = 96.) filename =
  Option.map mk_image @@ parse_from_file_ filename (string_of_units units) dpi

external parse_ : string -> string -> float -> image_raw option =
  "caml_nsvg_parse"

let parse ?(units = Px) ?(dpi = 96.) data =
  Option.map mk_image @@ parse_ data (string_of_units units) dpi

module Rasterizer = struct
  type raw
  type t = { mutable raw : raw option }
  let get rast =
    match rast.raw with
    | None -> raise (Invalid_argument "Nanosvg: rasterizer has been deleted")
    | Some raw -> raw

  external delete_ : raw -> unit = "caml_nsvg_delete_rasterizer" [@@noalloc]
  let delete rast =
    let raw = get rast in
    rast.raw <- None;
    delete_ raw

  let mk raw =
    let rast = { raw = Some raw } in
    Gc.finalise delete rast; rast

  external create_ : unit -> raw = "caml_nsvg_create_rasterizer" [@@noalloc]
  let create () = mk @@ create_ ()
end

type data8 = (int, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t

external rasterize_ :
  Rasterizer.raw -> image_raw ->
  float -> float -> float ->
  data8 -> int -> int -> int ->
  unit
  = "caml_nsvg_rasterize_bytecode" "caml_nsvg_rasterize_native" [@@noalloc]

let rasterize t img ~tx ~ty ~scale ~dst ~w ~h ?(stride = w * 4) () =
  if stride < w * 4 then
    raise (Invalid_argument "Nanosvg.Rasterizer.rasterize: invalid stride (too small)");
  if Bigarray.Array1.size_in_bytes dst < h * stride then
    raise (Invalid_argument "Nanosvg.Rasterizer.rasterize: destination buffer too small");
  rasterize_ (Rasterizer.get t) (image_get img) tx ty scale dst w h stride
