#!/bin/bash

cd spectre_oxi

cargo build --release

if [ "$(uname)" == "Darwin" ]; then
    cp target/release/libspectre_oxi.dylib ../lua/spectre_oxi.so
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    cp target/release/libspectre_oxi.so ../lua/spectre_oxi.so
elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ]; then
    cp target/release/libspectre_oxi.dll ../lua/spectre_oxi.dll
fi
rm -rf target
echo "Build Done"


