val rasterize_text :
  Nanosvg.image ->
  get_font:(family:string -> Stb_truetype.t) ->
  dst:Nanosvg.data8 ->
  scale:float ->
  tx:float -> ty:float ->
  w:int -> h:int ->
  unit ->
  unit
