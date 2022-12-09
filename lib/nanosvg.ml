(* Values of these types are constructed from C. Constructors integer
   representations MUST match the enum numbers from C *)
type line_join = Join_miter | Join_round | Join_bevel
type line_cap = Cap_butt | Cap_round | Cap_square
type fill_rule = Fillrule_nonzero | Fillrule_evenodd
type spread = Spread_pad | Spread_reflect | Spread_repeat
type text_anchor = Anchor_left | Anchor_center | Anchor_right
type text_style = Text_normal | Text_italic | Text_oblique
type stroke_align = Stroke_align_center | Stroke_align_inner | Stroke_align_outer

type gradient_stop = { color : Int32.t; offset : float }
type gradient = {
  xform : float array;
  spread : spread;
  fx : float; fy : float;
  stops : gradient_stop array;
}

type paint =
  | Paint_none
  | Paint_color of Int32.t
  | Paint_linear_gradient of gradient
  | Paint_radial_gradient of gradient

type box = {
  minx : float; miny : float;
  maxx : float; maxy : float;
}

type point = { x : float; y : float }

type path = {
  points : point array;
  closed : bool;
  bounds : box;
}

type text = {
  xform : float array;
  anchor : text_anchor;
  style : text_style;
  fontsize : float;
  fontfamily : string;
  s : string;
}

type shape_payload =
  | Shape_paths of path list
  | Shape_text of text

type shape = {
  id : string;
  fill : paint;
  stroke : paint;
  opacity : float;
  stroke_width : float;
  stroke_dash_offset : float;
  stroke_dash_array : float array;
  stroke_line_join : line_join;
  stroke_line_cap : line_cap;
  stroke_align : stroke_align;
  miter_limit : float;
  fill_rule : fill_rule;
  visible : bool;
  bounds : box;
  payload : shape_payload;
}

type image = {
  width : float;
  height : float;
  viewXform : float array;
  shapes : shape list;
}

module Image_data = struct
  type c_data
  external delete_image_c_data : c_data -> unit = "caml_nsvg_delete_image_c_data"

  (* block to allow attaching a finalizer *)
  type t = { dat : c_data }

  let mk dat =
    let img = { dat } in
    Gc.finalise (fun img -> delete_image_c_data img.dat) img;
    img

  external width_ : c_data -> float = "caml_nsvg_image_width"
  let width { dat } = width_ dat

  external height_ : c_data -> float = "caml_nsvg_image_height"
  let height { dat } = height_ dat

  external viewXform_ : c_data -> float array = "caml_nsvg_image_viewXform"
  let viewXform { dat } = viewXform_ dat
end

type units = Px | Pt | Pc | Mm | Cm | In

let string_of_units = function
  | Px -> "px"
  | Pt -> "pt"
  | Pc -> "pc"
  | Mm -> "mm"
  | Cm -> "cm"
  | In -> "in"

external parse_from_file_ : string -> string -> float -> Image_data.c_data option =
  "caml_nsvg_parse_from_file"

let parse_from_file ?(units = Px) ?(dpi = 96.) filename =
  Option.map Image_data.mk @@
  parse_from_file_ filename (string_of_units units) dpi

external parse_ : string -> string -> float -> Image_data.c_data option =
  "caml_nsvg_parse"

let parse ?(units = Px) ?(dpi = 96.) data =
  Option.map Image_data.mk @@
  parse_ data (string_of_units units) dpi

external lift_ : Image_data.c_data -> image = "caml_nsvg_lift"
let lift { Image_data.dat } = lift_ dat

module Rasterizer = struct
  type raw
  type t = { raw : raw }
  external delete : raw -> unit = "caml_nsvg_delete_rasterizer" [@@noalloc]

  external create : unit -> raw = "caml_nsvg_create_rasterizer" [@@noalloc]
  let create () =
    let rast = { raw = create () } in
    Gc.finalise (fun r -> delete r.raw) rast;
    rast
end

type data8 = (int, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t

external rasterize_ :
  Rasterizer.raw -> Image_data.c_data ->
  float -> float -> float ->
  data8 -> int -> int -> int ->
  unit
  = "caml_nsvg_rasterize_bytecode" "caml_nsvg_rasterize_native" [@@noalloc]

let rasterize (t: Rasterizer.t) { Image_data.dat } ~tx ~ty ~scale ~dst ~w ~h ?(stride = w * 4) () =
  if stride < w * 4 then
    raise (Invalid_argument "Nanosvg.Rasterizer.rasterize: invalid stride (too small)");
  if Bigarray.Array1.size_in_bytes dst < h * stride then
    raise (Invalid_argument "Nanosvg.Rasterizer.rasterize: destination buffer too small");
  rasterize_ t.raw dat tx ty scale dst w h stride
