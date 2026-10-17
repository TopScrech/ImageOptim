build: all

all: repng.cc fix-compiler

repng.cc:
	curl -L https://snapshot.debian.org/archive/debian/20120101T000000Z/pool/main/a/advancecomp/advancecomp_1.15.orig.tar.gz | tar xz --strip-components=1

clean:

install:

.PHONY: build all install clean

# The match byte is unused for literal symbols, but must still be initialized
fix-compiler: repng.cc compiler.patch
	@if grep -q 'BYTE aMatchByte;' 7z/LZMAEncoder.cc; then \
		sed -i.bak 's/BYTE aMatchByte;/BYTE aMatchByte = 0;/' 7z/LZMAEncoder.cc; \
		rm 7z/LZMAEncoder.cc.bak; \
	fi

	../scripts/apply-vendor-patch . compiler.patch

.PHONY: fix-compiler
