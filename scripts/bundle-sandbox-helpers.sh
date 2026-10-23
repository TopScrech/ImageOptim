#!/bin/sh
set -eu

# Pin both architectures and verify archives against the upstream release checksums
node_version=22.23.4
node_cache="$DERIVED_FILE_DIR/node-$node_version"
resources="$TARGET_BUILD_DIR/$UNLOCALIZED_RESOURCES_FOLDER_PATH"
mkdir -p "$node_cache" "$resources"

# Verify and copy the prebuilt optimizer tools, libraries, and license notices
(cd "$SRCROOT/Tools" && shasum -a 256 -c SHA256SUMS)
for helper in advpng gifsicle guetzli jpegoptim jpegtran oxipng pngcrush pngout pngquant svgcleaner zopflipng libimageoptimjpeg.dylib liblibpng.dylib svgo.js; do
    cp "$SRCROOT/Tools/$helper" "$resources/$helper"
done
cp -R "$SRCROOT/Tools/Licenses" "$resources/"
cp "$SRCROOT/Tools/versions.json" "$resources/tool-versions.json"
for architecture in arm64 x64; do
    case "$architecture" in
        arm64) checksum=c9e1dbc748b33ed2d14f42445191ecaf14c56259c7a9a26d0042c49ec2b66428 ;;
        x64) checksum=efcc2b0db6f94bf53eddb038fe2b370277a042bd29e4f19b8f8e23598795b819 ;;
    esac
    archive="$node_cache/node-$node_version-$architecture.tar.gz"
    if [ ! -f "$archive" ]; then
        curl --fail --location --retry 3 --output "$archive.download" "https://nodejs.org/dist/v$node_version/node-v$node_version-darwin-$architecture.tar.gz"
        mv "$archive.download" "$archive"
    fi
    printf '%s  %s\n' "$checksum" "$archive" | shasum -a 256 -c -
    if [ ! -f "$node_cache/$architecture/bin/node" ]; then
        mkdir -p "$node_cache/$architecture"
        tar -xzf "$archive" -C "$node_cache/$architecture" --strip-components=1 "node-v$node_version-darwin-$architecture/bin/node" "node-v$node_version-darwin-$architecture/LICENSE"
    fi
done
lipo -create "$node_cache/arm64/bin/node" "$node_cache/x64/bin/node" -output "$resources/node"
chmod 755 "$resources/node"
cp "$node_cache/arm64/LICENSE" "$resources/Node-LICENSE.txt"

# Sign the bundled executables with sandbox inheritance entitlements
if [ "${CODE_SIGNING_ALLOWED:-YES}" = YES ]; then
    signing_identity="${EXPANDED_CODE_SIGN_IDENTITY:--}"
    if [ -z "$signing_identity" ]; then signing_identity=-; fi
    for library in libimageoptimjpeg.dylib liblibpng.dylib; do
        codesign --force --sign "$signing_identity" "$resources/$library"
    done
    for helper in advpng gifsicle guetzli jpegoptim jpegtran oxipng pngcrush pngout pngquant svgcleaner zopflipng node; do
        set -- --force --sign "$signing_identity" --entitlements "$SRCROOT/PicPress/Helper.entitlements"
        if [ "${ENABLE_HARDENED_RUNTIME:-NO}" = YES ]; then
            set -- "$@" --options runtime
        fi
        codesign "$@" "$resources/$helper"
    done
fi
