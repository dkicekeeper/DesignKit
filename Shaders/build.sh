#!/bin/bash
# Compiles the Metal shaders in this folder into the .metallib files the package ships
# (Sources/DesignComponents/Resources/Shaders): one for devices, one for the simulator.
# Needs a Mac with Xcode and its Metal Toolchain (xcodebuild -downloadComponent MetalToolchain).
# CI runs it (.github/workflows/shaders.yml) whenever a shader changes and commits the result.
set -euo pipefail
cd "$(dirname "$0")"
OUT=../Sources/DesignComponents/Resources/Shaders
MIN_IOS=26.0

build() { # sdk, target suffix
    local sdk=$1 suffix=$2
    local frameworks
    frameworks="$(xcrun --sdk "$sdk" --show-sdk-path)/System/Library/Frameworks"
    xcrun --sdk "$sdk" metal \
        -target "air64-apple-ios${MIN_IOS}${suffix}" \
        -F "$frameworks" \
        -O3 \
        -o "$OUT/DesignKitShaders-$sdk.metallib" \
        ./*.metal
    echo "Built $OUT/DesignKitShaders-$sdk.metallib"
}

build iphoneos ""
build iphonesimulator "-simulator"
