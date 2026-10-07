//
//  Grain.metal
//  DesignKit
//
//  A fine, still grain over a surface (2.5.0), as a SwiftUI colour effect: each point is
//  nudged lighter or darker by a fixed hash of its position. It breaks the banding a smooth
//  gradient shows on a dark screen and gives aurora backgrounds a texture. `.grain()` drives it.
//
//  Not compiled by the package: CI compiles it with the other shaders (Shaders/build.sh).
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

[[ stitchable ]]
half4 Grain(float2 position, half4 color, float amount) {
    // A stable hash of the half-point cell: the same grain on every frame.
    float2 cell = floor(position * 2.0);
    float noise = fract(sin(dot(cell, float2(12.9898, 78.233))) * 43758.5453);
    half delta = half((noise - 0.5) * amount);
    return half4(color.rgb + delta * color.a, color.a);
}
