(lang dune 2.0)
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
   (ocaml (>= 4.08.0))
   (dune (>= 2.0))
   (odoc :with-doc))
  (synopsis "Simple SVG parser and rasterizer")
  (description "The NanoSVG library and rasterizer, packaged as an OCaml library"))
