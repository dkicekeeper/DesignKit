//
//  Holographic.metal
//  DesignKit
//
//  A holographic foil over a surface (2.6.0), as a SwiftUI colour effect: rainbow bands run
//  diagonally across it and slide as the light moves, with a soft sheen where the light falls.
//  `.holographic()` drives it from the finger.
//
//  Not compiled by the package: CI compiles it with the other shaders (Shaders/build.sh).
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

[[ stitchable ]]
half4 Holographic(float2 position, half4 color, float2 size, float2 light, float strength) {
    if (color.a < 0.001h) { return color; }
    float2 uv = position / max(size, float2(1.0));

    // Diagonal bands of the spectrum; the light slides them.
    float band = dot(uv - 0.5, normalize(float2(1.0, 0.6))) * 2.6 + light.x * 0.9 + light.y * 0.5;
    half3 rainbow = half3(0.5 + 0.5 * cos(6.28318 * (band + float3(0.0, 0.33, 0.67))));

    // A sheen where the light falls.
    float2 spot = 0.5 + light * 0.45;
    float sheen = exp(-length(uv - spot) * 3.2);

    half s = half(strength);
    half3 base = color.rgb;
    half3 foil = base * 0.65h + rainbow * color.a * 0.5h;
    half3 rgb = mix(base, foil, s) + half(sheen * 0.3) * s * color.a;
    return half4(min(rgb, half3(color.a)), color.a);
}
