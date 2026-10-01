//
//  MessageBanner.swift
//  Tenra
//
//  Created on 2026-02-16
//  Phase 15: Universal Message Banner Component
//

import SwiftUI
import DesignTokens
import DesignSupport

private enum BannerAnimation {
    /// Entrance spring — snappier than the old 0.6-response (~0.9s) settle; a toast
    /// belongs in the 200–500ms band.
    public static let entrance = Animation.spring(response: 0.4, dampingFraction: 0.8)
    /// Icon pop (delay applied at the call site during entrance only).
    public static let icon = Animation.spring(response: 0.5, dampingFraction: 0.6)
    public static let iconDelay: Double = 0.1
    /// Reduce-Motion / in-place-message-change fade: opacity only, no movement.
    public static let reducedFade = Animation.easeInOut(duration: 0.2)
    public static let hiddenScale: CGFloat = 0.92
    public static let hiddenOffset: CGFloat = -20
}

/// Universal message banner component supporting multiple message types
/// Consolidates ErrorMessageView and SuccessMessageView patterns
public struct MessageBanner: View {
    let message: String
    let type: MessageType
    let actionTitle: String?
    let action: (() -> Void)?

    @State private var isVisible = false
    @State private var iconScale: CGFloat = 0.5

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public enum MessageType {
        case success
        case error
        case warning
        case info

        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "exclamationmark.triangle"
            case .warning: return "exclamationmark.circle"
            case .info: return "info.circle"
            }
        }

        var tintColor: Color {
            switch self {
            case .success: return AppColors.success
            case .error: return AppColors.destructive
            case .warning: return AppColors.warning
            case .info: return AppColors.accent
            }
        }
    }

    public init(
        message: String,
        type: MessageType
    ) {
        self.message = message
        self.type = type
        self.actionTitle = nil
        self.action = nil
    }

    /// Banner with a trailing action button — "Undo" after a delete, "Retry" after a
    /// failure (Material snackbar action). The action does not dismiss the banner itself;
    /// clear your message state in it.
    public init(
        message: String,
        type: MessageType,
        actionTitle: String,
        action: @escaping () -> Void
    ) {
        self.message = message
        self.type = type
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        bannerContent
            .clipShape(.rect(cornerRadius: AppRadius.xl))
            .glassEffect(.regular
                .tint(type.tintColor.opacity(0.15))
                .interactive())
        // Under Reduce Motion the banner is a feedback surface, so the opacity fade
        // stays — only the scale/offset movement is dropped.
        .scaleEffect(isVisible || reduceMotion ? 1 : BannerAnimation.hiddenScale)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible || reduceMotion ? 0 : BannerAnimation.hiddenOffset)
        .onAppear {
            withAnimation(reduceMotion ? BannerAnimation.reducedFade : BannerAnimation.entrance) {
                isVisible = true
            }

            if reduceMotion {
                iconScale = 1.0
            } else {
                withAnimation(BannerAnimation.icon.delay(BannerAnimation.iconDelay)) {
                    iconScale = 1.0
                }
            }

            HapticManager.notification(type: type.hapticType)
        }
    }

    private var bannerContent: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: type.icon)
                .font(.system(size: AppIconSize.md))
                .foregroundStyle(type.tintColor)
                .scaleEffect(iconScale)
                .animation(reduceMotion ? nil : BannerAnimation.icon, value: iconScale)

            Text(message)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
                // Smooth a message that changes in place (same banner identity) instead
                // of a hard text swap.
                .contentTransition(.opacity)
                .animation(BannerAnimation.reducedFade, value: message)

            if let actionTitle, let action {
                Spacer(minLength: AppSpacing.sm)
                Button(action: action) {
                    Text(actionTitle)
                        .font(AppTypography.bodyEmphasis)
                        .foregroundStyle(type.tintColor)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AppSpacing.md)
    }
}

// MARK: - Haptic Feedback Extension

private extension MessageBanner.MessageType {
    var hapticType: UINotificationFeedbackGenerator.FeedbackType {
        switch self {
        case .success: return .success
        case .error: return .error
        case .warning: return .warning
        case .info: return .success
        }
    }
}

// MARK: - Convenience Initializers

public extension MessageBanner {
    /// Success message banner (green checkmark)
    static func success(_ message: String) -> MessageBanner {
        MessageBanner(message: message, type: .success)
    }

    /// Error message banner (red triangle)
    static func error(_ message: String) -> MessageBanner {
        MessageBanner(message: message, type: .error)
    }

    /// Warning message banner (orange circle)
    static func warning(_ message: String) -> MessageBanner {
        MessageBanner(message: message, type: .warning)
    }

    /// Info message banner (blue circle)
    static func info(_ message: String) -> MessageBanner {
        MessageBanner(message: message, type: .info)
    }
}

// MARK: - Preview
