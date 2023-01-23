(* a test that tries to poke and access the various values constructed from C to
   try to detect ill-formed data *)

let use (x: 'a) =
  Sys.opaque_identity ignore x

let use_box (b: Nanosvg.box) =
  use (b.minx +. 1., b.miny +. 1.,
       b.maxx +. 1., b.maxy +. 1.)

let use_point (p: Nanosvg.point) =
  use (p.x +. 1., p.y +. 1.)

let use_text (t: Nanosvg.text) =
  use (Array.fold_left (+.) 0. t.xform);
  use t.anchor;
  use (t.fontsize +. 1.);
  use (t.fontfamily ^ "x");
  use (t.s ^ "x")

let use_svg (img: Nanosvg.image) =
  let open Nanosvg in
  use (img.width, img.height);
  List.iter (fun s ->
    use (s.id, s.fill, s.stroke, s.opacity, s.stroke_width,
         s.stroke_dash_offset, s.stroke_dash_array, s.stroke_line_join,
         s.stroke_line_cap, s.miter_limit, s.fill_rule, s.visible);
    use_box s.bounds;
    match s.payload with
    | Shape_paths ps ->
      List.iter (fun p ->
        use p.closed;
        use_box p.bounds;
        Array.iter use_point p.points
      ) ps
    | Shape_text txt ->
      use_text txt
  ) img.shapes

let read_svg filename =
  Nanosvg.parse_from_file filename
  |> Option.get
  |> Nanosvg.lift
  |> use_svg

let () =
  List.iter read_svg (List.tl @@ Array.to_list Sys.argv)
