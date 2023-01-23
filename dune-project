(lang dune 2.7)
(generate_opam_files true)

(name nanosvg)
(version 0.1)
(source (github Armael/ocaml-nanosvg))
(authors "Mikko Mononen memon@inside.org" "Armaël Guéneau <armael.gueneau@ens-lyon.org>")
(maintainers "Armaël Guéneau <armael.gueneau@ens-lyon.org>")
(license MIT)

(package
  (name nanosvg)
  (depends
   (ocaml (>= 4.12.0))
   (dune (>= 2.0))
   (odoc :with-doc))
  (synopsis "Simple SVG parser and rasterizer")
  (description "The NanoSVG library and rasterizer, packaged as an OCaml library"))

(package
  (name nanosvg_text)
  (depends
   (ocaml (>= 4.12.0))
   (dune (>= 2.0))
   (nanosvg (>= 0.1))
   (stb_truetype (>= 0.7))
   (odoc :with-doc))
  (synopsis "Text rendering for NanoSVG text nodes")
  (description "Basic text rendering for NanoSVG text nodes using stb_truetype"))
