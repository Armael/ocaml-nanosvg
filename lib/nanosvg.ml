module Image = struct
  type t

  external width : t -> float = "caml_nsvg_image_width"
  external height : t -> float = "caml_nsvg_image_height"
end

type units = Px | Pt | Pc | Mm | Cm | In

let string_of_units = function
  | Px -> "px"
  | Pt -> "pt"
  | Pc -> "pc"
  | Mm -> "mm"
  | Cm -> "cm"
  | In -> "in"

external parse_from_file_ : string -> string -> float -> Image.t option =
  "caml_nsvg_parse_from_file"

let parse_from_file ?(units = Px) ?(dpi = 96.) filename =
  parse_from_file_ filename (string_of_units units) dpi

external parse_ : string -> string -> float -> Image.t option =
  "caml_nsvg_parse"

let parse ?(units = Px) ?(dpi = 96.) data =
  parse_ data (string_of_units units) dpi

external delete : Image.t -> unit = "caml_nsvg_delete" [@@noalloc]

module Rasterizer = struct
  type t
  external create : unit -> t = "caml_nsvg_create_rasterizer" [@@noalloc]
  external delete : t -> unit = "caml_nsvg_delete_rasterizer" [@@noalloc]
end

type data8 = (int, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t

external rasterize_ :
  Rasterizer.t -> Image.t ->
  float -> float -> float ->
  data8 -> int -> int -> int ->
  unit
  = "caml_nsvg_rasterize_bytecode" "caml_nsvg_rasterize_native" [@@noalloc]

let rasterize t img ~tx ~ty ~scale ~dst ~w ~h ?(stride = w * 4) () =
  if stride < w * 4 then
    raise (Invalid_argument "Nanosvg.Rasterizer.rasterize: invalid stride (too small)");
  if Bigarray.Array1.size_in_bytes dst < h * stride then
    raise (Invalid_argument "Nanosvg.Rasterizer.rasterize: destination buffer too small");
  rasterize_ t img tx ty scale dst w h stride
