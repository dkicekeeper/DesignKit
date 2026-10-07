//
//  ShaderLibraryTests.swift
//  DesignKit
//
//  The package ships its Metal shaders compiled (Shaders/build.sh). These pin that the
//  library for this platform is in the bundle and that the GPU accepts each shader, so a
//  missing or broken .metallib fails here instead of leaving `.ripple` silently off.
//

import Testing
import SwiftUI
@testable import DesignComponents

@MainActor
@Suite("Shader library")
struct ShaderLibraryTests {
    @Test("the compiled library is in the bundle")
    func libraryIsBundled() {
        #expect(DesignKitShaders.library != nil)
    }

    @Test("Ripple compiles as a layer effect")
    func rippleCompiles() async throws {
        let library = try #require(DesignKitShaders.library)
        let shader = library.Ripple(
            .float2(CGPoint.zero),
            .float(0),
            .float(RippleMetrics.amplitude),
            .float(RippleMetrics.frequency),
            .float(RippleMetrics.decay),
            .float(RippleMetrics.speed)
        )
        try await shader.compile(as: .layerEffect)
    }

    @Test("EdgeGlow compiles as a colour effect")
    func edgeGlowCompiles() async throws {
        let library = try #require(DesignKitShaders.library)
        let shader = library.EdgeGlow(
            .float2(CGSize(width: 390, height: 844)),
            .float(EdgeGlowMetrics.screenCornerRadius),
            .float(0),
            .float(0.5),
            .float(0),
            .float(EdgeGlowMetrics.thickness),
            .colorArray(VoiceWave.defaultColors)
        )
        try await shader.compile(as: .colorEffect)
    }
}
