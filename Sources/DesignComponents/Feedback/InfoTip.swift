//
//  InfoTip.swift
//  DesignKit
//
//  An ⓘ next to the name of a value that explains it (8.9.0, benchmark round 4: Astryx's
//  InfoTip; Carbon's Toggletip, Atlassian's Inline message). A tap opens a popover with a line or
//  two: what the number means, how it is counted ("30-day rolling average, recomputed nightly").
//  `Tooltip` is the bubble over a target (the amount of a tapped bar, a coachmark); this is the
//  explanation a person asks for.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// An ⓘ button that explains the value next to it in a popover.
///
/// ```swift
/// HStack(spacing: AppSpacing.xs) {
///     Text("Health score")
///     InfoTip("Your savings rate, debts and spending against your limits, from 0 to 100.")
/// }
///
/// Text("Rolling average")
///     .infoTip("The average of the last 30 days, recomputed every night.", title: "Rolling average")
/// ```
///
/// The glyph is small and grey and stays out of the way; the button around it is 44 pt for the
/// finger without moving the layout. The popover stays a popover on iPhone (it does not grow into
/// a sheet) and closes on a tap anywhere. Inside `.heroBackground` in dark mode the glyph is
/// white. VoiceOver reads "More information" (or "About <title>") and opens the text.
/// Strings: `infoTip.label`, `infoTip.about`. It explains, it shows no data, so it has no
/// skeleton.
public struct InfoTip: View {
    let message: String
    let title: String?

    @State private var isPresented = false
    @Environment(\.heroTone) private var heroTone

    /// - Parameters:
    ///   - message: The explanation: a sentence or two.
    ///   - title: A heading over it, usually the name of the value.
    public init(_ message: String, title: String? = nil) {
        self.message = message
        self.title = title
    }

    public var body: some View {
        Button {
            isPresented = true
        } label: {
            Icon("info.circle", size: AppIconSize.sm)
                .foregroundStyle(heroTone == .onColor ? AppColors.Text.primaryOnDark : AppColors.Text.secondary)
                // A 44 pt target around a 16 pt glyph, without taking the room.
                .padding(InfoTipMetrics.hitSlop)
                .contentShape(Rectangle())
                .padding(-InfoTipMetrics.hitSlop)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .popover(isPresented: $isPresented, arrowEdge: .bottom) {
            InfoTipContent(message: message, title: title)
                .presentationCompactAdaptation(.popover)
        }
    }

    private var accessibilityLabel: String {
        if let title {
            return String(localized: "infoTip.about", defaultValue: "About \(title)")
        }
        return String(localized: "infoTip.label", defaultValue: "More information")
    }
}

public extension View {
    /// The view with an `InfoTip` after it, on its first line: a label and its explanation.
    func infoTip(_ message: String, title: String? = nil) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: AppSpacing.xs) {
            self
            InfoTip(message, title: title)
                .alignmentGuide(.firstTextBaseline) { $0[VerticalAlignment.center] + InfoTipMetrics.baselineNudge }
        }
    }
}

/// The text in the popover: the title in bold, the explanation under it, wrapped at 280 pt.
private struct InfoTipContent: View {
    let message: String
    let title: String?

    var body: some View {
        InfoTipTextLayout(maxWidth: InfoTipMetrics.maxWidth) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                if let title {
                    Text(verbatim: title)
                        .font(AppTypography.bodySmall.weight(.semibold))
                        .foregroundStyle(AppColors.Text.primary)
                }
                Text(verbatim: message)
                    .font(AppTypography.bodySmall)
                    .foregroundStyle(AppColors.Text.secondary)
            }
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
        .accessibilityElement(children: .combine)
    }
}

/// Its content at its own width up to `maxWidth`, wrapped at `maxWidth` past it. A popover sizes
/// itself to its content's ideal size, where a long line would not wrap on its own.
private struct InfoTipTextLayout: Layout {
    let maxWidth: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let content = subviews.first else { return .zero }
        let ideal = content.sizeThatFits(.unspecified)
        guard ideal.width > maxWidth else { return ideal }
        return content.sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        subviews.first?.place(at: bounds.origin, proposal: ProposedViewSize(bounds.size))
    }
}

enum InfoTipMetrics {
    /// The text wraps past this width.
    static let maxWidth: CGFloat = 280
    /// Around the 16 pt glyph to a 44 pt target.
    static let hitSlop: CGFloat = (44 - AppIconSize.sm) / 2
    /// Lines the glyph's middle up a little under the label's baseline, by the middle of its
    /// lowercase letters.
    static let baselineNudge: CGFloat = 5
}
