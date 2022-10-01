all:
	dune build

example:
	dune exec -- example/example1.exe example/23.svg

clean:
	dune clean

test:
	dune runtest

.PHONY: all example clean test
