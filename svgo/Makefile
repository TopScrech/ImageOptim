all: ./build/svgo.js

./build/svgo.js: prebuilt/svgo.js prebuilt/svgo.js.LICENSE.txt
	mkdir -p build
	cp prebuilt/svgo.js prebuilt/svgo.js.LICENSE.txt build/

rebuild:
	npm ci
	./node_modules/.bin/webpack
	$(MAKE) all
	SVGO_TEST_SOURCE=1 npm test

clean:
	-rm -rf build node_modules

.PHONY: all clean rebuild
