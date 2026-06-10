//
//  SiriWaveView.swift
//  Tenra
//
//  Voice recording glow overlay wrapper.
//  Uses SiriGlowView (MeshGradient-based) for the visual effect.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Apple Intelligence–style edge glow overlay.
/// Designed as a full-screen `.overlay()` — passes through all touches.
/// Fades in on appear for smooth transition.
public struct SiriWaveRecordingView: View {

    @State private var isVisible = false

    public init() {}

    public var body: some View {
        SiriGlowView()
            .opacity(isVisible ? 1 : 0)
            .allowsHitTesting(false)
            .onAppear {
                withAnimation(AppAnimation.gentleSpring) {
                    isVisible = true
                }
            }
    }
}

// MARK: - Preview

