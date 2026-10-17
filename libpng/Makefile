VERSION=0.6.5
OPTIPNG_FILENAME=optipng-$(VERSION).tar.gz

build: all

all: png.h

png.h: /tmp/$(OPTIPNG_FILENAME)
	tar xzf /tmp/$(OPTIPNG_FILENAME) --strip-components=3 --exclude=Makefile --exclude='*.xcodeproj' optipng-$(VERSION)/lib/libpng
	sed -i.bak 's/defined(TARGET_OS_MAC)/0/' pngconf.h && rm pngconf.h.bak
	touch png.h

/tmp/$(OPTIPNG_FILENAME):
	curl -L http://downloads.sourceforge.net/project/optipng/OptiPNG/optipng-$(VERSION)/$(OPTIPNG_FILENAME) -o /tmp/$(OPTIPNG_FILENAME)

clean:
	test \! -e png.h || rm *.c png.h

install:

.PHONY: build all install clean
