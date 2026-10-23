VERSION=1.8.13
ARCHIVE=/tmp/imageoptim-pngcrush-$(VERSION).tar.gz

build: all

all: pngcrush.c

$(ARCHIVE):
	curl -fL -o $@.tmp https://downloads.sourceforge.net/project/pmt/pngcrush/$(VERSION)/pngcrush-$(VERSION).tar.gz
	mv $@.tmp $@

tmp/pngcrush.c: Makefile pngcrush.patch $(ARCHIVE)
	printf '%s  %s\n' bac37d4b2be88d7e88aadcde9661beb3a513a90e7d26784f906c1e2da8ba332e $(ARCHIVE) | shasum -a 256 -c -
	test -d tmp || mkdir -p tmp
	tar xzf $(ARCHIVE) -C tmp --strip-components=1 --exclude=Makefile
	touch tmp/pngcrush.c

pngcrush.c: tmp/pngcrush.c
	( cd tmp; patch --forward -p1 < ../pngcrush.patch )
	-rm tmp/png.h tmp/pngconf.h 2>/dev/null
	cp tmp/*.[ch] ./
	touch pngcrush.c

clean:
	-rm -rf tmp *.c *.h $(ARCHIVE) patched

install: all

.PHONY: all build clean
