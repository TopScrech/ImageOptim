#!/bin/sh
set -eu

# Install the toolchain required by the bundled Rust helpers
installer=$(mktemp -t picpress-rustup)
trap 'rm -f "$installer"' EXIT
curl --proto '=https' --tlsv1.2 --fail --silent --show-error --location \
    https://sh.rustup.rs -o "$installer"
sh "$installer" -y --no-modify-path --profile minimal \
    --default-toolchain 1.92.0 \
    --target aarch64-apple-darwin,x86_64-apple-darwin

export PATH="$HOME/.cargo/bin:$PATH"
cargo --version
rustup target list --installed

# Populate generated source files before Xcode evaluates build inputs
repository=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
for dependency in libpng zlib advpng gifsicle guetzli jpegoptim libjpeg pngcrush zopfli-png PicPress svgo; do
    make -C "$repository/$dependency" all
done
