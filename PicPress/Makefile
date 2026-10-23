SUBMODULES=../svgcleaner/src

build: all

all: $(SUBMODULES) pngout fix-rust-manifests

$(SUBMODULES): ../.gitmodules
	../scripts/fetch-submodule $@ && touch $@

pngout:
	curl -LO https://www.jonof.id.au/files/kenutils/pngout-20230322-mac.zip
	unzip -p pngout-20230322-mac.zip pngout-20230322-mac/pngout > pngout
	chmod a+rx pngout
	codesign -s "-" ./pngout --force

clean:
	-rm -rf pngout pngout-20230322-mac.zip

install: all

.PHONY: build all install clean

fix-rust-manifests: $(SUBMODULES) ../pngquant/compiler.patch ../svgcleaner/compiler.patch
	$(MAKE) -C ../pngquant all
	../scripts/apply-vendor-patch ../pngquant/src ../pngquant/compiler.patch
	../scripts/apply-vendor-patch ../svgcleaner/src ../svgcleaner/compiler.patch

.PHONY: fix-rust-manifests
