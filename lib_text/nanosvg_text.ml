(* Text rendering is not optimized:
   - there is no caching of glyph bitmaps
   - no attempt is made of reusing buffers to limit allocations
*)

let box_merge box1 box2 =
  Stb_truetype.{
    x0 = min box1.x0 box2.x0;
    y0 = min box1.y0 box2.y0;
    x1 = max box1.x1 box2.x1;
    y1 = max box1.y1 box2.y1;
  }

let prerender_glyphs font scale (l: Stb_truetype.glyph list) =
  let rec with_kerning = function
    | x :: y :: xs ->
      let kern = Stb_truetype.kern_advance font x y in
      (x, kern) :: with_kerning (y :: xs)
    | [x] -> [(x, 0)]
    | [] -> []
  in
  let l = with_kerning l in
  let xpos = ref 0. in
  List.map (fun (glyph, kern) ->
    let shift_x = !xpos -. Float.floor !xpos in
    let hmetrics = Stb_truetype.hmetrics font glyph in
    let bitmap =
      Stb_truetype.get_glyph_bitmap_subpixel font glyph ~scale_x:scale ~scale_y:scale
        ~shift_x ~shift_y:0. in
    let x = int_of_float !xpos + bitmap.xoff in
    let y = bitmap.yoff in
    xpos := !xpos +. scale *. (float hmetrics.advance_width +. float kern);
    (bitmap, x, y)
  ) l

(* baseline is at y=0; first glyph origin is at x=0 *)
let glyphs_box (glyphs: (Stb_truetype.glyph_bitmap * int * int) list) =
  let glyph_box (bitmap, x, y) =
    Stb_truetype.{ x0 = x; y0 = y; x1 = x + bitmap.w; y1 = y + bitmap.h }
  in
  match List.map glyph_box glyphs with
  | [] -> None
  | g :: gs -> Some (List.fold_left box_merge g gs)

let render_glyphs font scale (l: Stb_truetype.glyph list) =
  let gs = prerender_glyphs font scale l in
  match glyphs_box gs with
  | None ->
    Stb_truetype.{
      buf = Bigarray.Array1.create Bigarray.int8_unsigned Bigarray.c_layout 0;
      w = 0; h = 0; xoff = 0; yoff = 0
    }
  | Some text_box ->
    let w = text_box.x1 - text_box.x0 in
    let h = text_box.y1 - text_box.y0 in
    let buf = Bigarray.Array1.create Bigarray.int8_unsigned Bigarray.c_layout (w * h) in
    Bigarray.Array1.fill buf 0;
    List.iter (fun ((bitmap: Stb_truetype.glyph_bitmap), x, y) ->
      let dx = x - text_box.x0 in
      let dy = y - text_box.y0 in
      for j = 0 to bitmap.h - 1 do
        for i = 0 to bitmap.w - 1 do
          let text_i = i+dx and text_j = j+dy in
          if 0 <= text_i && text_i < w && 0 <= text_j && text_j < h then (
            let a0 = buf.{text_j * w + text_i} in
            let a1 = bitmap.buf.{j * bitmap.w + i} in
            buf.{text_j * w + text_i} <- a0 + a1 - (a0 * a1) / 255 (* alpha blending *)
          )
        done
      done
    ) gs;
    Stb_truetype.{ buf; w; h; xoff = text_box.x0; yoff = text_box.y0 }

let glyphs_of_string font s =
  String.to_seq s
  |> Seq.map Char.code
  |> Seq.map (Stb_truetype.get font)
  |> List.of_seq

let rasterize_text
    (svg: Nanosvg.image)
    ~(get_font: family:string -> Stb_truetype.t)
    ~(dst: Nanosvg.data8)
    ~(scale: float)
    ~(tx: float) ~(ty: float)
    ~(w: int) ~(h: int)
    ()
  =
  List.iter (fun shape ->
    match shape.Nanosvg.payload with
    | Shape_paths _ -> ()
    | Shape_text txt ->
      let supported_transform =
        (* check that there is no rotation component to the transform *)
        (txt.xform.(1) = 0. && txt.xform.(2) = 0.) &&
        (* check this is a uniform scaling transformation *)
        (txt.xform.(0) = txt.xform.(3))
      in
      (* we skip text nodes with transforms we don't handle *)
      if supported_transform && shape.visible then begin
        let font = get_font ~family:txt.fontfamily in
        let text_scale = txt.xform.(0) *. scale in
        let scale = Stb_truetype.scale_for_mapping_em_to_pixels font (text_scale *. txt.fontsize) in
        let bitmap = render_glyphs font scale (glyphs_of_string font txt.s) in

        let anchor_x = int_of_float (tx +. text_scale *. txt.xform.(4)) in
        let anchor_y = int_of_float (ty +. text_scale *. txt.xform.(5)) in
        let anchor_dx, anchor_dy =
          match txt.anchor with
          | Anchor_left -> 0, bitmap.yoff
          | Anchor_center -> -bitmap.w/2, bitmap.yoff
          | Anchor_right -> -bitmap.w, bitmap.yoff
        in
        let text_x, text_y = anchor_x + anchor_dx, anchor_y + anchor_dy in

        let text_r, text_g, text_b =
          match shape.Nanosvg.fill with
          | Paint_color col ->
            Int32.(logand col 0xffl |> to_int,
                   logand (shift_right col 8) 0xffl |> to_int,
                   logand (shift_right col 16) 0xffl |> to_int)
          | _ -> (0,0,0)
        in

        for j = 0 to bitmap.h - 1 do
          for i = 0 to bitmap.w - 1 do
            let dst_i = i+text_x and dst_j = j+text_y in
            if 0 <= dst_i && dst_i < w && 0 <= dst_j && dst_j < h then (
              (* alpha blending *)
              let off = (dst_j * w + dst_i) * 4 in
              let adst = dst.{off + 3} in
              let atext = bitmap.buf.{j * bitmap.w + i} in
              let ares = adst + atext - (adst * atext) / 255 in
              let col cdst ctext =
                if ares = 0 then 0 else
                  (ctext * atext + cdst * adst - cdst * atext * adst / 255) / ares
              in
              dst.{off} <- col dst.{off} text_r;
              dst.{off + 1} <- col dst.{off+1} text_g;
              dst.{off + 2} <- col dst.{off+2} text_b;
              dst.{off + 3} <- ares
            )
          done
        done
      end
  ) svg.shapes
