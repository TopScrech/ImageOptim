VERSION=2.6
ARCHIVE=/tmp/imageoptim-advancecomp-$(VERSION).tar.gz

build: all

all: .source-$(VERSION) fix-compiler remove-source-headers

$(ARCHIVE):
	curl -fL https://github.com/amadvance/advancecomp/releases/download/v$(VERSION)/advancecomp-$(VERSION).tar.gz -o $@.tmp
	mv $@.tmp $@

.source-$(VERSION): $(ARCHIVE) Makefile
	printf '%s  %s\n' b07d77735540409771cbe1b6df165b5151c11bb9c3d8f01290be0ec88ec3498f $(ARCHIVE) | shasum -a 256 -c -
	tar xzf $(ARCHIVE) --strip-components=1 --exclude=Makefile --exclude=config.h
	touch $@

clean:

install:

.PHONY: build all install clean

# The match byte is unused for literal symbols, but must still be initialized
fix-compiler: .source-$(VERSION) compiler.patch
	@if grep -q 'BYTE aMatchByte;' 7z/LZMAEncoder.cc; then \
		sed -i.bak 's/BYTE aMatchByte;/BYTE aMatchByte = 0;/' 7z/LZMAEncoder.cc; \
		rm 7z/LZMAEncoder.cc.bak; \
	fi

	../scripts/apply-vendor-patch . compiler.patch

.PHONY: fix-compiler

remove-source-headers: fix-compiler source-headers.patch
	../scripts/apply-vendor-patch . source-headers.patch

.PHONY: remove-source-headers
