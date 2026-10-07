//
//  EdgeGlow.metal
//  DesignKit
//
//  Light along the edges of a surface (2.4.0), as a SwiftUI colour effect: colours flow
//  around the rim, the band breathes in width, and a voice level makes it wider and brighter.
//  One pass per pixel, no blur. `EdgeGlow` drives it.
//
//  Not compiled by the package: CI compiles it with the other shaders (Shaders/build.sh).
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

/// Signed distance from `p` to a rounded rectangle centred at the origin: half size `b`,
/// corner radius `r`. Negative inside.
static float roundedRectDistance(float2 p, float2 b, float r) {
    float2 q = abs(p) - b + r;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

/// Distance to the nearest edge as a smooth minimum of the four: no creases along the
/// diagonals, as the exact distance has, so a wide light stays soft. Below 0 near a corner.
static float softEdgeDistance(float2 position, float2 size, float k) {
    float4 d = max(float4(position.x, size.x - position.x, position.y, size.y - position.y), 0.0);
    float4 e = exp(-d / k);
    return -k * log(e.x + e.y + e.z + e.w);
}

/// The palette around the rim: `x` in 0…1 goes once round, the last colour blending back
/// into the first.
static half3 rimColor(float x, device const half4 *colors, int count) {
    float f = fract(x) * float(count);
    int i = int(floor(f)) % count;
    int j = (i + 1) % count;
    half t = half(smoothstep(0.0, 1.0, fract(f)));
    return mix(colors[i].rgb, colors[j].rgb, t);
}

[[ stitchable ]]
half4 EdgeGlow(
    float2 position,
    half4 color,
    float2 size,
    float cornerRadius,
    float time,
    float level,
    float flow,
    float thickness,
    device const half4 *colors,
    int count
) {
    float2 center = size * 0.5;
    float2 p = position - center;

    // Where on the rim it is, 0…1 clockwise; corrected for the aspect so a tall screen
    // spreads its colours evenly.
    float around = atan2(p.y * (size.x / max(size.y, 1.0)), p.x) / (2.0 * M_PI_F) + 0.5;
    float angle = around * 2.0 * M_PI_F;

    // The band breathes: three slow waves of width travel round the rim.
    float wobble = 1.0
        + 0.30 * sin(angle * 3.0 + time * 1.1)
        + 0.20 * sin(angle * 5.0 - time * 0.7)
        + 0.15 * sin(angle * 2.0 + time * 1.7);
    // The depth follows the voice but stays a fraction of the surface, so a card keeps a dark
    // middle as a screen does.
    float reach = min(size.x, size.y) * 0.12;
    float width = max(min(thickness * (1.0 + level * 1.2), reach) * wobble, 1.0);

    // A soft bloom that falls off fast inside, so the middle stays dark even on a small surface,
    // and a hot rim along the exact rounded edge.
    float soft = max(softEdgeDistance(position, size, width * 0.6), 0.0);
    float bloom = exp(-pow(soft / width, 1.3));
    float edgeDepth = max(-roundedRectDistance(p, center, min(cornerRadius, min(center.x, center.y))), 0.0);
    float rim = exp(-edgeDepth / max(width * 0.18, 0.5));
    float intensity = clamp(bloom * (0.55 + 0.45 * level) + rim * 0.6, 0.0, 1.0);

    half3 rgb = rimColor(around + flow, colors, max(count, 1));
    // The rim runs hotter, towards white, the louder the voice.
    rgb = mix(rgb, half3(1.0), half(rim * 0.35 * (0.4 + level)));

    half alpha = half(intensity);
    return half4(rgb * alpha, alpha);
}
