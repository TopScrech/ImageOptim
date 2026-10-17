build: all

all: zopfli/src fix-compiler

zopfli/src: ../.gitmodules
	../scripts/fetch-submodule zopfli && touch zopfli/src

.PHONY: build all install clean


fix-compiler: zopfli/src compiler.patch
	../scripts/apply-vendor-patch zopfli compiler.patch

.PHONY: fix-compiler
