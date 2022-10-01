let use (x: 'a) =
  Sys.opaque_identity ignore x

let use_box (b: Nanosvg.box) =
  use (int_of_float b.minx, int_of_float b.miny,
       int_of_float b.maxx, int_of_float b.maxy)

let use_bezier_point (p: Nanosvg.bezier_point) =
  use (int_of_float p.x0, int_of_float p.y0,
       int_of_float p.cpx1, int_of_float p.cpy1,
       int_of_float p.cpx2, int_of_float p.cpy2,
       int_of_float p.x1, int_of_float p.y1)

let use_svg (img: Nanosvg.image) =
  let open Nanosvg in
  use (img.width, img.height);
  List.iter (fun s ->
    use (s.id, s.fill, s.stroke, s.opacity, s.stroke_width,
         s.stroke_dash_offset, s.stroke_dash_array, s.stroke_line_join,
         s.stroke_line_cap, s.miter_limit, s.fill_rule, s.visible);
    use_box s.bounds;
    List.iter (fun p ->
      use p.closed;
      use_box p.bounds;
      Array.iter use_bezier_point p.points
    ) s.paths;
  ) img.shapes

let read_svg filename =
  Nanosvg.parse_from_file filename
  |> Option.get
  |> Nanosvg.lift
  |> use_svg

let () =
  read_svg "../example/23.svg";
  read_svg "../example/drawing.svg"
