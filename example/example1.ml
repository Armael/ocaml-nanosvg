open Tsdl

let main filename =
  let img =
    match Nanosvg.parse_from_file ~units:Px filename with
    | Some img -> img
    | None -> Sdl.log "Could not open or parse input file"; exit 1
  in
  let rast = Nanosvg.Rasterizer.create () in
  let w = int_of_float (Nanosvg.Image.width img) in
  let h = int_of_float (Nanosvg.Image.height img) in
  let dst = Bigarray.Array1.create Bigarray.Int8_unsigned Bigarray.C_layout (w * h * 4) in
  Nanosvg.rasterize rast img ~tx:0. ~ty:0. ~scale:1. ~dst ~w ~h ();

  begin match Sdl.init Sdl.Init.video with
    | Error (`Msg e) -> Sdl.log "Init error: %s" e; exit 1
    | Ok () -> ()
  end;
  let win =
    match Sdl.create_window ~w ~h "SDL OpenGL" Sdl.Window.opengl with
    | Error (`Msg e) -> Sdl.log "Create window error: %s" e; exit 1
    | Ok win -> win
  in
  let renderer =
    match Sdl.create_renderer win with
    | Error (`Msg e) -> Sdl.log "Create renderer error: %s" e; exit 1
    | Ok renderer -> renderer
  in
  for x = 0 to w-1 do
    for y = 0 to h-1 do
      let i = (x + y * w) * 4 in
      let () = Result.get_ok @@
        Sdl.set_render_draw_color renderer dst.{i} dst.{i+1} dst.{i+2} dst.{i+3} in
      let () = Result.get_ok @@
        Sdl.render_draw_point renderer x y in
      ()
    done
  done;
  Sdl.render_present renderer;
  Sdl.delay 3_000l;
  Sdl.destroy_window win;
  Nanosvg.Image.delete img;
  Nanosvg.Rasterizer.delete rast;
  Sdl.quit ();
  exit 0

let () =
  match Sys.argv |> Array.to_list |> List.tl with
  | [file] -> main file
  | _ ->
    Printf.eprintf "usage: %s <filename.svg>\n" Sys.argv.(0); exit 1
