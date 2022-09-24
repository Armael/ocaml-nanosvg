type line_join = Join_miter | Join_round | Join_bevel
type line_cap = Cap_butt | Cap_round | Cap_square
type fill_rule = Fillrule_nonzero | Fillrule_evenodd

module Gradient : sig
  type t
end

type paint =
  | Paint_none
  | Paint_color of Int32.t
  | Paint_linear_gradient of Gradient.t
  | Paint_radial_gradient of Gradient.t

module Shape : sig
  type t
  val fill : t -> paint
  val stroke : t -> paint
  val opacity : t -> float
  val stroke_width : t -> float
  val stroke_dash_offset : t -> float
  val stroke_dash_count : t -> int
  val stroke_line_join : t -> line_join
  val stroke_line_cap : t -> line_cap
  val miter_limit : t -> float
  val fill_rule : t -> fill_rule
end

module Image : sig
  type t
  val width : t -> float
  val height : t -> float
  val delete : t -> unit
  val shapes : t -> Shape.t list
end

type units = Px | Pt | Pc | Mm | Cm | In

val parse_from_file : ?units:units -> ?dpi:float -> string -> Image.t option
val parse : ?units:units -> ?dpi:float -> string -> Image.t option

module Rasterizer : sig
  type t
  val create : unit -> t
  val delete : t -> unit
end

type data8 = (int, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t

val rasterize :
  Rasterizer.t -> Image.t ->
  tx:float -> ty:float -> scale:float ->
  dst:data8 -> w:int -> h:int -> ?stride:int ->
  unit ->
  unit
