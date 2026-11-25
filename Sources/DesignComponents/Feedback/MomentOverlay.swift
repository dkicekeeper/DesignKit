//
//  MomentOverlay.swift
//  DesignKit
//
//  A big moment of success over the whole screen (vNext): a goal reached, a debt settled, a month
//  inside the budgets, a reward earned. No card: the screen behind dims and blurs, the hero (any
//  view: a mascot, a medal, a symbol) springs in at the centre, a title and a line or two rise in
//  under it, an optional reward under them, confetti behind the hero for a celebration. Buttons at
//  the bottom: an optional primary one ("See the goal") and the one that closes it ("Close").
//  A tap outside the hero and the buttons, a swipe down and VoiceOver's escape close it too.
//
//  Shown inline by a host (an overlay of its own), or over the whole app, sheets, tab bar and
//  navigation included, in a window of its own by `MomentPresenter` (MomentPresenter.swift).
//
//  Every close plays the exit first (everything fades, the hero shrinks a little), then runs the
//  button's action. Under Reduce Motion and `.designKitMotion(false)` the moment comes and goes by
//  opacity only; the haptic stays (the success pattern with the confetti, a light tap without).
//
//  The texts come from the host: the component has no strings of its own.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// A button of a `MomentOverlay`: its title and what it does.
public struct MomentAction {
    /// The button's title.
    public let title: String
    /// What it does, once the moment has gone.
    public let action: () -> Void

    public init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }
}

/// A moment of success over the whole screen, without a card: the screen behind dims and blurs,
/// the hero springs in at the centre with a title and a line or two under it, and buttons wait
/// at the bottom.
///
/// ```swift
/// MomentPresenter.shared.present {
///     MomentOverlay(
///         title: "Goal reached",
///         message: "A new bike: 250 000 saved.",
///         celebrates: true,
///         primary: MomentAction("See the goal") { router.open(goal) },
///         dismissTitle: "Close"
///     ) {
///         ParticleCreature(mood: .celebrating).frame(width: 220, height: 220)
///     }
/// }
/// ```
///
/// Only good news, one at a time: never a warning, an error or something the person must act
/// on. The hero is sized by the host; it is one VoiceOver element with the title after its own
/// label (just the title when it has none). A close by the primary button runs `primary.action`,
/// any other close (the dismiss button, a tap outside the hero and the buttons, a swipe down,
/// VoiceOver's escape) runs `onDismiss`, each after the exit has played.
public struct MomentOverlay<Hero: View, Reward: View>: View {
    let title: String
    let message: String?
    let celebrates: Bool
    let primary: MomentAction?
    let dismissTitle: String
    let onDismiss: () -> Void
    let hero: Hero
    let reward: Reward

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.designKitMotion) private var designKitMotion
    @Environment(\.momentDismissal) private var dismissal

    @State private var stage: MomentStage = .entering
    /// Counts entrances: the confetti and the haptic play on each.
    @State private var entrances = 0
    /// How far the content follows a finger pulling it down.
    @State private var pull: CGFloat = 0
    /// Whether the content is scrolled to its top (a swipe down closes only from there).
    @State private var isAtTop = true
    /// Whether the drag under way began with the content at its top; `nil` between drags.
    @State private var dragBeganAtTop: Bool?

    /// - Parameters:
    ///   - title: What happened, in a few words ("Goal reached").
    ///   - message: A line or two under it.
    ///   - celebrates: Confetti behind the hero and the success haptic; otherwise a light tap.
    ///   - primary: The main button ("See the goal", "Wear it"); its action runs after the exit.
    ///   - dismissTitle: The button that closes the moment ("Close", "Later"). Without `primary`
    ///     it is the one filled button.
    ///   - onDismiss: Runs after the exit when the moment is closed any way but the primary
    ///     button.
    ///   - hero: The view at the centre, sized by the host (a mascot, a medal, a symbol).
    ///   - reward: What the moment gives, under the text (an accessory, a badge).
    public init(
        title: String,
        message: String? = nil,
        celebrates: Bool = false,
        primary: MomentAction? = nil,
        dismissTitle: String,
        onDismiss: @escaping () -> Void = {},
        @ViewBuilder hero: () -> Hero,
        @ViewBuilder reward: () -> Reward
    ) {
        self.title = title
        self.message = message
        self.celebrates = celebrates
        self.primary = primary
        self.dismissTitle = dismissTitle
        self.onDismiss = onDismiss
        self.hero = hero()
        self.reward = reward()
    }

    /// Movement as well as opacity: off under Reduce Motion and `.designKitMotion(false)`.
    private var moves: Bool { !reduceMotion && designKitMotion }
    private var isShown: Bool { stage == .shown }

    public var body: some View {
        ZStack {
            scrim

            VStack(spacing: 0) {
                GeometryReader { proxy in
                    ScrollView {
                        moment
                            .frame(maxWidth: .infinity, minHeight: proxy.size.height)
                            // The empty space round the hero and the text is scrim too: a tap
                            // there closes the moment (the scroll view would keep it from the
                            // scrim behind).
                            .background {
                                Color.clear
                                    .contentShape(Rectangle())
                                    .onTapGesture { close(onDismiss) }
                                    .accessibilityHidden(true)
                            }
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    .onScrollGeometryChange(for: Bool.self) { geometry in
                        geometry.contentOffset.y <= -geometry.contentInsets.top + 1
                    } action: { _, atTop in
                        isAtTop = atTop
                    }
                }
                buttons
            }
            .offset(y: pull)
            // Confetti behind the hero, above the scrim.
            .backgroundPreferenceValue(MomentHeroBoundsKey.self) { anchor in
                if celebrates, let anchor {
                    GeometryReader { proxy in
                        let rect = proxy[anchor]
                        Color.clear
                            .frame(width: rect.width, height: rect.height)
                            .celebration(trigger: entrances)
                            .position(x: rect.midX, y: rect.midY)
                    }
                }
            }
        }
        .hapticCue(.tap, trigger: entrances) { _, _ in !celebrates }
        .simultaneousGesture(swipeDown)
        .allowsHitTesting(stage != .leaving)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape) { close(onDismiss) }
        .onAppear(perform: appear)
    }

    // MARK: - Parts

    /// The dim and the blur over the app, edge to edge.
    private var scrim: some View {
        Rectangle()
            .fill(.regularMaterial)
            .overlay(AppColors.Background.scrim)
            .ignoresSafeArea()
            .opacity(isShown ? 1 : 0)
            .animation(isShown ? AppAnimation.smooth : AppAnimation.snappy, value: stage)
            .contentShape(Rectangle())
            .onTapGesture { close(onDismiss) }
            .accessibilityHidden(true)
    }

    /// The hero, the text and the reward, centred.
    private var moment: some View {
        VStack(spacing: AppSpacing.xl) {
            hero
                // The hero's whole frame is the hero: a tap on it does not close the moment.
                .contentShape(Rectangle())
                .accessibilityElement(children: .combine)
                .accessibilityLabel { label in
                    label
                    Text(verbatim: title)
                }
                .accessibilityAddTraits(.isImage)
                .anchorPreference(key: MomentHeroBoundsKey.self, value: .bounds) { $0 }
                .scaleEffect(moves ? heroScale : 1)
                .opacity(isShown ? 1 : 0)
                .animation(isShown ? AppAnimation.expressive : AppAnimation.snappy, value: stage)

            VStack(spacing: AppSpacing.sm) {
                Text(verbatim: title)
                    .font(AppTypography.h2)
                    .foregroundStyle(AppColors.Text.primary)
                    .accessibilityAddTraits(.isHeader)
                if let message, !message.isEmpty {
                    Text(verbatim: message)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.Text.secondary)
                }
            }
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            // A tap on the text is a tap on the scrim.
            .allowsHitTesting(false)
            .modifier(MomentRise(stage: stage, moves: moves, delay: MomentOverlayMetrics.textDelay))

            if Reward.self != EmptyView.self {
                reward
                    .accessibilityElement(children: .contain)
                    .modifier(MomentRise(stage: stage, moves: moves, delay: MomentOverlayMetrics.rewardDelay))
            }
        }
        .padding(.vertical, AppSpacing.xxl)
        .screenPadding()
        .frame(maxWidth: MomentOverlayMetrics.maxContentWidth)
    }

    /// The primary button over the dismiss one, full width at the bottom.
    private var buttons: some View {
        VStack(spacing: AppSpacing.sm) {
            if let primary {
                DSButton(primary.title, fullWidth: true) { close(primary.action) }
            }
            DSButton(dismissTitle, appearance: primary == nil ? .primary : .flat, fullWidth: true) {
                close(onDismiss)
            }
        }
        .padding(.top, AppSpacing.md)
        .padding(.bottom, AppSpacing.lg)
        .screenPadding()
        .frame(maxWidth: MomentOverlayMetrics.maxContentWidth)
        .modifier(MomentRise(stage: stage, moves: moves, delay: MomentOverlayMetrics.buttonsDelay))
    }

    /// Grows in from well below its size on the expressive spring, shrinks a little on the way out.
    private var heroScale: CGFloat {
        switch stage {
        case .entering: MomentOverlayMetrics.heroEntranceScale
        case .shown: 1
        case .leaving: MotionTransitionMetrics.popScale
        }
    }

    // MARK: - Swipe down

    private var swipeDown: some Gesture {
        DragGesture(minimumDistance: MomentOverlayMetrics.dragMinimum)
            .onChanged { value in
                guard isShown else { return }
                if dragBeganAtTop == nil { dragBeganAtTop = isAtTop }
                let down = value.translation.height
                guard dragBeganAtTop == true, down > 0, down > abs(value.translation.width) else {
                    pull = 0
                    return
                }
                // The content follows the finger, a little behind it.
                pull = down * MomentOverlayMetrics.pullResistance
            }
            .onEnded { value in
                let beganAtTop = dragBeganAtTop == true
                dragBeganAtTop = nil
                let down = max(value.translation.height, value.predictedEndTranslation.height)
                if beganAtTop, isShown, value.translation.height > 0, down > MomentOverlayMetrics.dismissDistance {
                    close(onDismiss)
                } else {
                    withAnimation(AppAnimation.snappy) { pull = 0 }
                }
            }
    }

    // MARK: - Entrance and exit

    private func appear() {
        guard stage == .entering else { return }
        stage = .shown
        entrances += 1
        // VoiceOver moves into the moment and hears what happened.
        AccessibilityNotification.ScreenChanged().post()
        AccessibilityAnnouncer.announce(spokenText)
    }

    /// Plays the exit, then hands `action` to the presenter (which removes its window first) or,
    /// shown inline, runs it.
    private func close(_ action: (() -> Void)?) {
        guard stage == .shown else { return }
        stage = .leaving
        let dismissal = dismissal
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(MomentOverlayMetrics.exitDuration))
            if let dismissal {
                dismissal.finish(action)
            } else {
                action?()
            }
        }
    }

    /// The title and the message as one announcement.
    private var spokenText: String {
        guard let message, !message.isEmpty else { return title }
        let endsSentence = title.last.map { ".!?…".contains($0) } ?? false
        return endsSentence ? "\(title) \(message)" : "\(title). \(message)"
    }
}

public extension MomentOverlay where Reward == EmptyView {
    /// A moment without a reward under its text.
    init(
        title: String,
        message: String? = nil,
        celebrates: Bool = false,
        primary: MomentAction? = nil,
        dismissTitle: String,
        onDismiss: @escaping () -> Void = {},
        @ViewBuilder hero: () -> Hero
    ) {
        self.init(
            title: title,
            message: message,
            celebrates: celebrates,
            primary: primary,
            dismissTitle: dismissTitle,
            onDismiss: onDismiss,
            hero: hero,
            reward: { EmptyView() }
        )
    }
}

// MARK: - Support

enum MomentStage: Hashable {
    case entering, shown, leaving
}

enum MomentOverlayMetrics {
    /// The hero grows from this on the expressive spring (`.popIn` grows from 92 %; a moment's
    /// hero comes from further).
    static let heroEntranceScale: CGFloat = 0.6
    /// After the hero: the text, the reward, the buttons (within `MotionBudget.maxStagger`).
    static let textDelay: Double = 0.1
    static let rewardDelay: Double = 0.18
    static let buttonsDelay: Double = 0.24
    /// The exit (`AppAnimation.snappy`) before the action runs.
    static let exitDuration: Double = MotionBudget.feedback
    /// A wide screen (iPad) keeps the moment a phone's width.
    static let maxContentWidth: CGFloat = 480
    /// A swipe down: where it starts, how far the content follows the finger, how far closes.
    static let dragMinimum: CGFloat = 12
    static let pullResistance: CGFloat = 0.5
    static let dismissDistance: CGFloat = 120
}

/// Rises 12 pt and sharpens while fading in, after `delay` (`.riseIn`'s movement, driven by the
/// moment's stage so the layout never moves); fades on the way out. Opacity only without motion.
private struct MomentRise: ViewModifier {
    let stage: MomentStage
    let moves: Bool
    let delay: Double

    func body(content: Content) -> some View {
        let entering = stage == .entering
        content
            .offset(y: moves && entering ? MotionTransitionMetrics.rise : 0)
            .blur(radius: moves && entering ? MotionTransitionMetrics.blur : 0)
            .opacity(stage == .shown ? 1 : 0)
            .animation(stage == .shown ? AppAnimation.smooth.delay(delay) : AppAnimation.snappy, value: stage)
    }
}

/// The hero's bounds, for the confetti behind it.
private struct MomentHeroBoundsKey: PreferenceKey {
    static let defaultValue: Anchor<CGRect>? = nil
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = value ?? nextValue()
    }
}

/// How a moment in `MomentPresenter`'s window asks to be removed: the presenter takes the window
/// away, then runs the button's action.
struct MomentDismissal {
    let finish: @MainActor (_ action: (() -> Void)?) -> Void
}

extension EnvironmentValues {
    /// Set by `MomentPresenter` on its window; `nil` for a moment a host shows inline.
    @Entry var momentDismissal: MomentDismissal? = nil
}
