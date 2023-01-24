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

(* The patched nanosvg we use to get text nodes does not do XML entity parsing.
   We do it ourselves below... *)
module XMLEntities = struct
  (* from https://github.com/dbuenzli/xmlm/blob/master/test/xhtml.ml *)
  let entities = [
    ("nbsp", "\194\160");
    ("iexcl", "\194\161");
    ("cent", "\194\162");
    ("pound", "\194\163");
    ("curren", "\194\164");
    ("yen", "\194\165");
    ("brvbar", "\194\166");
    ("sect", "\194\167");
    ("uml", "\194\168");
    ("copy", "\194\169");
    ("ordf", "\194\170");
    ("laquo", "\194\171");
    ("not", "\194\172");
    ("shy", "\194\173");
    ("reg", "\194\174");
    ("macr", "\194\175");
    ("deg", "\194\176");
    ("plusmn", "\194\177");
    ("sup2", "\194\178");
    ("sup3", "\194\179");
    ("acute", "\194\180");
    ("micro", "\194\181");
    ("para", "\194\182");
    ("middot", "\194\183");
    ("cedil", "\194\184");
    ("sup1", "\194\185");
    ("ordm", "\194\186");
    ("raquo", "\194\187");
    ("frac14", "\194\188");
    ("frac12", "\194\189");
    ("frac34", "\194\190");
    ("iquest", "\194\191");
    ("Agrave", "\195\128");
    ("Aacute", "\195\129");
    ("Acirc", "\195\130");
    ("Atilde", "\195\131");
    ("Auml", "\195\132");
    ("Aring", "\195\133");
    ("AElig", "\195\134");
    ("Ccedil", "\195\135");
    ("Egrave", "\195\136");
    ("Eacute", "\195\137");
    ("Ecirc", "\195\138");
    ("Euml", "\195\139");
    ("Igrave", "\195\140");
    ("Iacute", "\195\141");
    ("Icirc", "\195\142");
    ("Iuml", "\195\143");
    ("ETH", "\195\144");
    ("Ntilde", "\195\145");
    ("Ograve", "\195\146");
    ("Oacute", "\195\147");
    ("Ocirc", "\195\148");
    ("Otilde", "\195\149");
    ("Ouml", "\195\150");
    ("times", "\195\151");
    ("Oslash", "\195\152");
    ("Ugrave", "\195\153");
    ("Uacute", "\195\154");
    ("Ucirc", "\195\155");
    ("Uuml", "\195\156");
    ("Yacute", "\195\157");
    ("THORN", "\195\158");
    ("szlig", "\195\159");
    ("agrave", "\195\160");
    ("aacute", "\195\161");
    ("acirc", "\195\162");
    ("atilde", "\195\163");
    ("auml", "\195\164");
    ("aring", "\195\165");
    ("aelig", "\195\166");
    ("ccedil", "\195\167");
    ("egrave", "\195\168");
    ("eacute", "\195\169");
    ("ecirc", "\195\170");
    ("euml", "\195\171");
    ("igrave", "\195\172");
    ("iacute", "\195\173");
    ("icirc", "\195\174");
    ("iuml", "\195\175");
    ("eth", "\195\176");
    ("ntilde", "\195\177");
    ("ograve", "\195\178");
    ("oacute", "\195\179");
    ("ocirc", "\195\180");
    ("otilde", "\195\181");
    ("ouml", "\195\182");
    ("divide", "\195\183");
    ("oslash", "\195\184");
    ("ugrave", "\195\185");
    ("uacute", "\195\186");
    ("ucirc", "\195\187");
    ("uuml", "\195\188");
    ("yacute", "\195\189");
    ("thorn", "\195\190");
    ("yuml", "\195\191");
    ("lt", "<");
    ("gt", ">");
    ("amp", "&");
    ("apos", "'");
    ("quot", "\"");
    ("OElig", "\197\146");
    ("oelig", "\197\147");
    ("Scaron", "\197\160");
    ("scaron", "\197\161");
    ("Yuml", "\197\184");
    ("circ", "\203\134");
    ("tilde", "\203\156");
    ("ensp", "\226\128\130");
    ("emsp", "\226\128\131");
    ("thinsp", "\226\128\137");
    ("zwnj", "\226\128\140");
    ("zwj", "\226\128\141");
    ("lrm", "\226\128\142");
    ("rlm", "\226\128\143");
    ("ndash", "\226\128\147");
    ("mdash", "\226\128\148");
    ("lsquo", "\226\128\152");
    ("rsquo", "\226\128\153");
    ("sbquo", "\226\128\154");
    ("ldquo", "\226\128\156");
    ("rdquo", "\226\128\157");
    ("bdquo", "\226\128\158");
    ("dagger", "\226\128\160");
    ("Dagger", "\226\128\161");
    ("permil", "\226\128\176");
    ("lsaquo", "\226\128\185");
    ("rsaquo", "\226\128\186");
    ("euro", "\226\130\172");
    ("fnof", "\198\146");
    ("Alpha", "\206\145");
    ("Beta", "\206\146");
    ("Gamma", "\206\147");
    ("Delta", "\206\148");
    ("Epsilon", "\206\149");
    ("Zeta", "\206\150");
    ("Eta", "\206\151");
    ("Theta", "\206\152");
    ("Iota", "\206\153");
    ("Kappa", "\206\154");
    ("Lambda", "\206\155");
    ("Mu", "\206\156");
    ("Nu", "\206\157");
    ("Xi", "\206\158");
    ("Omicron", "\206\159");
    ("Pi", "\206\160");
    ("Rho", "\206\161");
    ("Sigma", "\206\163");
    ("Tau", "\206\164");
    ("Upsilon", "\206\165");
    ("Phi", "\206\166");
    ("Chi", "\206\167");
    ("Psi", "\206\168");
    ("Omega", "\206\169");
    ("alpha", "\206\177");
    ("beta", "\206\178");
    ("gamma", "\206\179");
    ("delta", "\206\180");
    ("epsilon", "\206\181");
    ("zeta", "\206\182");
    ("eta", "\206\183");
    ("theta", "\206\184");
    ("iota", "\206\185");
    ("kappa", "\206\186");
    ("lambda", "\206\187");
    ("mu", "\206\188");
    ("nu", "\206\189");
    ("xi", "\206\190");
    ("omicron", "\206\191");
    ("pi", "\207\128");
    ("rho", "\207\129");
    ("sigmaf", "\207\130");
    ("sigma", "\207\131");
    ("tau", "\207\132");
    ("upsilon", "\207\133");
    ("phi", "\207\134");
    ("chi", "\207\135");
    ("psi", "\207\136");
    ("omega", "\207\137");
    ("thetasym", "\207\145");
    ("upsih", "\207\146");
    ("piv", "\207\150");
    ("bull", "\226\128\162");
    ("hellip", "\226\128\166");
    ("prime", "\226\128\178");
    ("Prime", "\226\128\179");
    ("oline", "\226\128\190");
    ("frasl", "\226\129\132");
    ("weierp", "\226\132\152");
    ("image", "\226\132\145");
    ("real", "\226\132\156");
    ("trade", "\226\132\162");
    ("alefsym", "\226\132\181");
    ("larr", "\226\134\144");
    ("uarr", "\226\134\145");
    ("rarr", "\226\134\146");
    ("darr", "\226\134\147");
    ("harr", "\226\134\148");
    ("crarr", "\226\134\181");
    ("lArr", "\226\135\144");
    ("uArr", "\226\135\145");
    ("rArr", "\226\135\146");
    ("dArr", "\226\135\147");
    ("hArr", "\226\135\148");
    ("forall", "\226\136\128");
    ("part", "\226\136\130");
    ("exist", "\226\136\131");
    ("empty", "\226\136\133");
    ("nabla", "\226\136\135");
    ("isin", "\226\136\136");
    ("notin", "\226\136\137");
    ("ni", "\226\136\139");
    ("prod", "\226\136\143");
    ("sum", "\226\136\145");
    ("minus", "\226\136\146");
    ("lowast", "\226\136\151");
    ("radic", "\226\136\154");
    ("prop", "\226\136\157");
    ("infin", "\226\136\158");
    ("ang", "\226\136\160");
    ("and", "\226\136\167");
    ("or", "\226\136\168");
    ("cap", "\226\136\169");
    ("cup", "\226\136\170");
    ("int", "\226\136\171");
    ("there4", "\226\136\180");
    ("sim", "\226\136\188");
    ("cong", "\226\137\133");
    ("asymp", "\226\137\136");
    ("ne", "\226\137\160");
    ("equiv", "\226\137\161");
    ("le", "\226\137\164");
    ("ge", "\226\137\165");
    ("sub", "\226\138\130");
    ("sup", "\226\138\131");
    ("nsub", "\226\138\132");
    ("sube", "\226\138\134");
    ("supe", "\226\138\135");
    ("oplus", "\226\138\149");
    ("otimes", "\226\138\151");
    ("perp", "\226\138\165");
    ("sdot", "\226\139\133");
    ("lceil", "\226\140\136");
    ("rceil", "\226\140\137");
    ("lfloor", "\226\140\138");
    ("rfloor", "\226\140\139");
    ("lang", "\226\140\169");
    ("rang", "\226\140\170");
    ("loz", "\226\151\138");
    ("spades", "\226\153\160");
    ("clubs", "\226\153\163");
    ("hearts", "\226\153\165");
    ("diams", "\226\153\166"); ]

  let decode_entities (txt : string) =
    let buf = Buffer.create 80 in
    let read_entity (pos : int) =
      match String.index_from_opt txt pos ';' with
      | Some pos_semi ->
        Some (String.sub txt pos (pos_semi - pos), pos_semi + 1)
      | None -> (* ill-formed entity *)
        None
    in
    let parse_entity (ent : string) =
      try
        if String.length ent > 1 && ent.[0] = '#' then (
          Buffer.add_utf_8_uchar buf
            (Uchar.of_int
               (int_of_string (String.sub ent 1 (String.length ent - 1))))
        ) else Buffer.add_string buf (List.assoc ent entities)
      with Failure _ | Not_found -> ()
    in
    let rec loop (pos : int) =
      if pos < String.length txt then
        let dec = String.get_utf_8_uchar txt pos in
        if Uchar.utf_decode_uchar dec = Uchar.of_char '&' then begin
          match read_entity (pos + 1) with
          | None -> ()
          | Some (entity, next_pos) ->
            parse_entity entity;
            loop next_pos
        end else begin
          if Uchar.utf_decode_is_valid dec then
            Buffer.add_utf_8_uchar buf (Uchar.utf_decode_uchar dec);
          loop (pos + Uchar.utf_decode_length dec)
        end
    in
    loop 0; Buffer.contents buf

  let decode (img : image) =
    let decode_shape_payload = function
      | Shape_paths ps -> Shape_paths ps
      | Shape_text txt -> Shape_text { txt with s = decode_entities txt.s } in
    let decode_shape (s : shape) =
      { s with payload = decode_shape_payload s.payload} in
    { img with shapes = List.map decode_shape img.shapes }
end

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
let lift { Image_data.dat } = XMLEntities.decode (lift_ dat)

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
