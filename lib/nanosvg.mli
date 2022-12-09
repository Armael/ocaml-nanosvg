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

module Image_data : sig
  type t
  val width : t -> float
  val height : t -> float
  val viewXform : t -> float array
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
