//
//  Dissolve.metal
//  DesignKit
//
//  A view breaking into dust (2.6.0), as a SwiftUI layer effect: a grain of noise decides
//  which pixels go first, the edge of what remains glows, and loose grains drift up as they
//  go. `progress` runs from 0 (whole) to 1 (gone). `.transition(.dissolve)` drives it.
//
//  Not compiled by the package: CI compiles it with the other shaders (Shaders/build.sh).
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

static float hash(float2 p) {
    return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

/// Smooth value noise, 0…1.
static float noise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    float2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + float2(1, 0)), u.x),
               mix(hash(i + float2(0, 1)), hash(i + float2(1, 1)), u.x), u.y);
}

[[ stitchable ]]
half4 Dissolve(float2 position, SwiftUI::Layer layer, float2 size, float progress, half4 edge) {
    float2 uv = position / max(size, float2(1.0));
    // Coarse and fine noise, and a lean so the top right goes first.
    float grain = noise(position / 7.0) * 0.65 + noise(position / 2.0) * 0.35;
    float order = grain * 0.8 + (1.0 - uv.y) * 0.1 + uv.x * 0.1;
    float threshold = progress * 1.2 - 0.1;

    // Loose grains drift up a little as they go.
    float loosening = smoothstep(threshold, threshold + 0.12, order);
    half4 color = layer.sample(position + float2(0.0, (1.0 - loosening) * 10.0 * progress));

    if (order < threshold) { return half4(0.0h); }
    // The edge of what remains glows in `edge`.
    half rim = half(1.0 - smoothstep(threshold, threshold + 0.05, order));
    half3 rgb = mix(color.rgb, edge.rgb * color.a, rim * 0.9h);
    return half4(rgb, color.a);
}
