build: all

all: guetzli/src fix-compiler

guetzli/src: ../.gitmodules
	../scripts/fetch-submodule guetzli && touch guetzli/src

.PHONY: build all install clean


fix-compiler: guetzli/src compiler.patch
	../scripts/apply-vendor-patch guetzli compiler.patch

.PHONY: fix-compiler
