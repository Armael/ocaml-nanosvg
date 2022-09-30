type line_join = Join_miter | Join_round | Join_bevel
type line_cap = Cap_butt | Cap_round | Cap_square
type fill_rule = Fillrule_nonzero | Fillrule_evenodd
type spread = Spread_pad | Spread_reflect | Spread_repeat

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

type bezier_point = {
  x0 : float; y0 : float;
  cpx1 : float; cpy1 : float;
  cpx2 : float; cpy2 : float;
  x1 : float; y1 : float;
}

type path = {
  points : bezier_point array;
  closed : bool;
  bounds : box;
}

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
  miter_limit : float;
  fill_rule : fill_rule;
  visible : bool;
  bounds : box;
  paths : path list;
}

type image = {
  width : float;
  height : float;
  shapes : shape list;
}

module Image_data : sig
  type t
  val width : t -> float
  val height : t -> float
end

type units = Px | Pt | Pc | Mm | Cm | In

val parse_from_file : ?units:units -> ?dpi:float -> string -> Image_data.t option
val parse : ?units:units -> ?dpi:float -> string -> Image_data.t option
val lift : Image_data.t -> image

module Rasterizer : sig
  type t
  val create : unit -> t
end

type data8 = (int, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t

val rasterize :
  Rasterizer.t -> Image_data.t ->
  tx:float -> ty:float -> scale:float ->
  dst:data8 -> w:int -> h:int -> ?stride:int ->
  unit ->
  unit
