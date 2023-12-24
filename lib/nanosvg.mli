(** {1 Raw SVG images} *)

(** Raw images of type {!Image_data.t} are the direct result of parsing SVG
    data. They cannot be inspected directly from OCaml (except for their size
    and viewbox), but can be fed as-is to the rasterize function. The {!lift}
    function allows to convert from a raw image into an inspectable SVG image.*)
module Image_data : sig
  type t
  val width : t -> float
  val height : t -> float
  val viewXform : t -> float array
end

(** {1 SVG images} *)

(** An inspectable SVG image has type {!image}. It corresponds to a list of
    {!shape}s, where each shape is either a {!text} element or a list of
    {!path}s. Shapes and paths are additionally associated with various
    attributes, defined below.
*)

type line_join = Join_miter | Join_round | Join_bevel
type line_cap = Cap_butt | Cap_round | Cap_square
type fill_rule = Fillrule_nonzero | Fillrule_evenodd
type spread = Spread_pad | Spread_reflect | Spread_repeat

(** Horizontal text alignment. {!Anchor_left} is the default. *)
type text_anchor = Anchor_left | Anchor_center | Anchor_right

(** Text style. {!Text_normal} is the default. *)
type text_style = Text_normal | Text_italic | Text_oblique

(** Stroke alignment with respect to the path. {!Stroke_align_center} is the
    default, with the stroke centered on the path. With {!Stroke_align_inner}
    the stroke is inside the path, and with {!Stroke_align_outer} it is outside
    the path. *)
type stroke_align = Stroke_align_center | Stroke_align_inner | Stroke_align_outer

type gradient_stop = { color : Int32.t; offset : float }
type gradient = {
  xform : float array; (** transform (array of size 6) *)
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

(** A SVG path. *)
type path = {
  points : point array; (** cubic bezier points: x0,y0, \[cpx1,cpy1,cpx2,cpy2,x1,y1\], ... *)
  closed : bool; (** whether shapes should be treated as closed *)
  bounds : box; (** a tight bounding box of the shape *)
}

(** A SVG text element. *)
type text = {
  xform : float array; (** text transform (array of size 6); text is positioned at (0,0) in the transformed space *)
  anchor : text_anchor; (** horizontal alignment *)
  style : text_style; (** text style *)
  fontsize : float; (** font size *)
  fontfamily : string; (** font family *)
  s : string; (** the text itself *)
}

type shape_payload =
  | Shape_paths of path list
  | Shape_text of text

(** A SVG shape. *)
type shape = {
  id : string; (** optional 'id' attribute of the shape or its group *)
  fill : paint; (** fill paint *)
  stroke : paint; (** stroke paint *)
  opacity : float; (** opacity of the shape *)
  stroke_width : float; (** stroke width (scaled) *)
  stroke_dash_offset : float; (** stroke dash offset (scaled) *)
  stroke_dash_array : float array; (** stroke dash array (scaled) *)
  stroke_line_join : line_join; (** stroke join type*)
  stroke_line_cap : line_cap; (** stroke cap type *)
  stroke_align : stroke_align; (** stroke alignment *)
  miter_limit : float; (** miter limit *)
  fill_rule : fill_rule; (** fill rule *)
  visible : bool; (** is the shape visible *)
  bounds : box; (** tight bounding box of the shape *)
  payload : shape_payload; (** the shape data itself: either a path or text *)
}

(** A complete SVG image. *)
type image = {
  width : float; (** width of the image *)
  height : float; (** height of the image *)
  viewXform : float array; (** viewbox transform (array of size 6) *)
  shapes : shape list; (** shapes *)
}

(** {1 Parsing} *)

type units = Px | Pt | Pc | Mm | Cm | In

(** [parse ~units ~dpi s] parses [s] as SVG data.
    - [units] indicates the unit that should be used for the paths' coordinates and dimensions.
    - [dpi] controls how the unit conversion is done.

    By default, [units] is [Px] and [dpi] is [96].
*)
val parse : ?units:units -> ?dpi:float -> string -> Image_data.t option

(** [parse_from_file fn] parses the contents of the file named [fn] as SVG data.
    See {!parse} for the description of the optional arguments. *)
val parse_from_file : ?units:units -> ?dpi:float -> string -> Image_data.t option

(** [lift img] converts the raw image [img] into its ocaml representation. *)
val lift : Image_data.t -> image

(** {1 Rasterization} *)

(** A {!Rasterizer.t} is a handle to an opaque rasterizer context. Reusing the
    same rasterizer context accross multiple calls to {!rasterize} is more
    efficient than recreating a new context each time.
*)
module Rasterizer : sig
  type t
  val create : unit -> t
end

type data8 = (int, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t

(** [rasterize r img ~tx ~ty ~scale ~dst ~w ~h ?stride ()] rasterizes a raw SVG
    image [img] by writing RGBA pixels (non-premultiplied alpha) to [dst].
    - [tx], [ty]: image offset (applied after scaling)
    - [scale]: image scale
    - [dst]: buffer for the destination image data, 4 bytes per pixel (RGBA)
    - [w], [h]: width, height of the image to render
    - [stride]: number of bytes per scaleline in the destination buffer.
      It is [w*4] by default.
*)
val rasterize :
  Rasterizer.t -> Image_data.t ->
  tx:float -> ty:float -> scale:float ->
  dst:data8 -> w:int -> h:int -> ?stride:int ->
  unit ->
  unit
