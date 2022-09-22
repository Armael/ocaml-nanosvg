module Image : sig
  type t
  val width : t -> float
  val height : t -> float
  val delete : t -> unit
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
