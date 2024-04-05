#!/bin/bash

set -e

cd spectre_oxi

cargo build --release

[ "$CARGO_TARGET_DIR" = "" ] && CARGO_TARGET_DIR=target

if [ "$(uname)" == "Darwin" ]; then
    cp "$CARGO_TARGET_DIR"/release/libspectre_oxi.dylib ../lua/spectre_oxi.so
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    cp "$CARGO_TARGET_DIR"/release/libspectre_oxi.so ../lua/spectre_oxi.so
elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ]; then
    cp "$CARGO_TARGET_DIR"/release/libspectre_oxi.dll ../lua/spectre_oxi.dll
fi
rm -rf target
echo "Build Done"
