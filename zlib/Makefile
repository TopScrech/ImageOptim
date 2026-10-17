
# zlib is not built here! It's included as part of libpng instead.

VERSION=0.7.7

build: all

all: zlib.h fix-platform

zlib.h:
	curl -L http://downloads.sourceforge.net/project/optipng/OptiPNG/optipng-$(VERSION)/optipng-$(VERSION).tar.gz | tar xz --strip-components=3 --exclude=Makefile optipng-$(VERSION)/src/zlib

clean:

install:

.PHONY: build all install clean

# TARGET_OS_MAC includes modern macOS, which must use the Apple platform branch
fix-platform: zlib.h
	@if grep -q '^\#if defined(MACOS) || defined(TARGET_OS_MAC)' zutil.h; then \
		sed -i.bak 's/defined(MACOS) || defined(TARGET_OS_MAC)/(defined(MACOS) || defined(TARGET_OS_MAC)) \&\& !defined(__APPLE__)/' zutil.h; \
		rm zutil.h.bak; \
	fi

.PHONY: fix-platform
