OCaml bindings to Nano SVG
==========================

[Nano SVG](https://github.com/memononen/nanosvg) is a simple single-header SVG
parser and rasterizer.

This library implements OCaml bindings to NanoSVG while vendoring the C
implementation, thus providing a standalone OCaml library.

## Example program

See `example/example1.ml`. Building it additionally requires `tsdl` to be installed.

```
opam install tsdl

make example
# or
dune exec -- example/example1.exe example/23.svg
```
