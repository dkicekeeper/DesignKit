//
//  Ripple.metal
//  DesignKit
//
//  A ripple spreading from a point (2.3.0), as a SwiftUI layer effect. After Apple's sample
//  "Create custom visual effects with SwiftUI" (WWDC24). `.ripple(trigger:at:)` drives it.
//
//  Not compiled by the package: CI compiles it into the two .metallib files in
//  Sources/DesignComponents/Resources/Shaders (Shaders/build.sh, docs/motion.md), so the apps
//  build without Xcode's optional Metal Toolchain.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

[[ stitchable ]]
half4 Ripple(
    float2 position,
    SwiftUI::Layer layer,
    float2 origin,
    float time,
    float amplitude,
    float frequency,
    float decay,
    float speed
) {
    // The wave reaches this pixel `distance / speed` seconds after it leaves the origin.
    float distance = length(position - origin);
    time = max(0.0, time - distance / speed);

    // A sine wave fading out exponentially.
    float amount = amplitude * sin(frequency * time) * exp(-decay * time);

    // Push the pixel towards or away from the origin by that amount, and sample there.
    float2 direction = normalize(position - origin);
    half4 color = layer.sample(position + amount * direction);

    // Crests are a little lighter, troughs a little darker.
    color.rgb += 0.3 * (amount / amplitude) * color.a;
    return color;
}
