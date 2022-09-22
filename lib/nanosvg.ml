module Image = struct
  type raw
  external width_ : raw -> float = "caml_nsvg_image_width"
  external height_ : raw -> float = "caml_nsvg_image_height"

  type t = { mutable raw : raw option }
  let get img =
    match img.raw with
    | None -> raise (Invalid_argument "Nanosvg: image has been deleted")
    | Some raw -> raw

  let width img = width_ (get img)
  let height img = height_ (get img)

  external delete_ : raw -> unit = "caml_nsvg_delete" [@@noalloc]

  let delete img =
    let raw = get img in
    img.raw <- None;
    delete_ raw

  let mk raw =
    let img = { raw = Some raw } in
    Gc.finalise delete img; img
end

type units = Px | Pt | Pc | Mm | Cm | In

let string_of_units = function
  | Px -> "px"
  | Pt -> "pt"
  | Pc -> "pc"
  | Mm -> "mm"
  | Cm -> "cm"
  | In -> "in"

external parse_from_file_ : string -> string -> float -> Image.raw option =
  "caml_nsvg_parse_from_file"

let parse_from_file ?(units = Px) ?(dpi = 96.) filename =
  Option.map Image.mk @@ parse_from_file_ filename (string_of_units units) dpi

external parse_ : string -> string -> float -> Image.raw option =
  "caml_nsvg_parse"

let parse ?(units = Px) ?(dpi = 96.) data =
  Option.map Image.mk @@ parse_ data (string_of_units units) dpi

module Rasterizer = struct
  type raw
  external create_ : unit -> raw = "caml_nsvg_create_rasterizer" [@@noalloc]
  external delete_ : raw -> unit = "caml_nsvg_delete_rasterizer" [@@noalloc]

  type t = { mutable raw : raw option }
  let get rast =
    match rast.raw with
    | None -> raise (Invalid_argument "Nanosvg: rasterizer has been deleted")
    | Some raw -> raw

  let delete rast =
    let raw = get rast in
    rast.raw <- None;
    delete_ raw

  let mk raw =
    let rast = { raw = Some raw } in
    Gc.finalise delete rast; rast

  let create () = mk @@ create_ ()
end

type data8 = (int, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t

external rasterize_ :
  Rasterizer.raw -> Image.raw ->
  float -> float -> float ->
  data8 -> int -> int -> int ->
  unit
  = "caml_nsvg_rasterize_bytecode" "caml_nsvg_rasterize_native" [@@noalloc]

let rasterize t img ~tx ~ty ~scale ~dst ~w ~h ?(stride = w * 4) () =
  if stride < w * 4 then
    raise (Invalid_argument "Nanosvg.Rasterizer.rasterize: invalid stride (too small)");
  if Bigarray.Array1.size_in_bytes dst < h * stride then
    raise (Invalid_argument "Nanosvg.Rasterizer.rasterize: destination buffer too small");
  rasterize_ (Rasterizer.get t) (Image.get img) tx ty scale dst w h stride
