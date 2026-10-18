build: all

all: patched

# Upstream now includes lossy compression and the full color implementation
patched: orig/src/gifsicle.c Makefile
	rm -rf gifsicle
	mkdir gifsicle
	cp -R orig/src orig/include gifsicle/
	touch patched

orig/src/gifsicle.c:
	../scripts/fetch-submodule orig

clean:
	rm -rf patched gifsicle

.PHONY: build all install clean
