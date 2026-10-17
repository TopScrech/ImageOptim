build: all

all: patched

patched: orig/src gifsicle-1.89-imageoptim.patch compiler.patch
	-rm -rf gifsicle
	cp -R orig gifsicle
	patch --forward -p1 -d gifsicle < gifsicle-1.89-imageoptim.patch
	patch --forward -p1 -d gifsicle < compiler.patch && touch patched

orig/src: ../.gitmodules
	../scripts/fetch-submodule orig && touch orig/src

clean:
	-rm -rf patched gifsicle

.PHONY: build all install clean
