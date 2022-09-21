all:
	dune build

example:
	dune exec -- example/example1.exe example/23.svg

clean:
	dune clean

.PHONY: all example clean
