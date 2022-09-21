OCaml bindings to Nano SVG
==========================

[Nano SVG](https://github.com/memononen/nanosvg) is a simple single-header SVG
parser and rasterizer.

This library implements OCaml bindings to NanoSVG while vendoring the C
implementation, thus providing a standalone OCaml library.

The OCaml bindings are currently incomplete, and mostly offer access to the
rasterizer. In particular, they lack functions to inspect the structure of the
SVG data produced by the parser. Contributions are welcome (this should not be
too hard to add)!
