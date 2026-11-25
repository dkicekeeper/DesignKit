//
//  MomentPresenter.swift
//  DesignKit
//
//  Shows a `MomentOverlay` over the whole app (8.18.0): in a window of its own above the app's
//  windows, so over its sheets (they live in the app's main window), the tab bar and navigation,
//  and below system alerts. The window exists only while a moment is up; afterwards it is torn
//  down, so touches reach the app whenever no moment is shown.
//
//  The window takes the app's own light or dark choice and its accent. The moment's blur is a
//  material on the window's full-screen scrim, so it blurs the app's windows under it (to be
//  checked on a device).
//

import SwiftUI
import UIKit
import DesignTokens

/// Presents a `MomentOverlay` over the whole app, in a window of its own.
///
/// ```swift
/// MomentPresenter.shared.present(onDismissed: { moments.next() }) {
///     MomentOverlay(title: "Debt settled", celebrates: true, dismissTitle: "Close") {
///         ParticleCreature(mood: .proud).frame(width: 220, height: 220)
///     }
/// }
/// ```
///
/// One moment at a time: `present` refuses while another is up. The moment closes itself (its
/// buttons, a tap outside, a swipe down, VoiceOver's escape): it plays its exit, the window goes,
/// then the button's action runs (it may navigate or open a sheet), then `onDismissed`.
@available(iOSApplicationExtension, unavailable)
@MainActor
public final class MomentPresenter {
    /// The app's presenter.
    public static let shared = MomentPresenter()

    private var window: UIWindow?
    private var onDismissed: (() -> Void)?
    /// Tells a close of an earlier moment from the current one.
    private var presentation = 0

    init() {}

    /// Whether a moment is up.
    public var isPresenting: Bool { window != nil }

    /// Shows `content` (a MomentOverlay) over the whole app, in a window of its own above the
    /// app's windows: over sheets, the tab bar and navigation. Returns false and shows nothing
    /// while another moment is up, or when there is no foreground-active window scene.
    ///
    /// - Parameter onDismissed: Runs once the moment has closed itself and its window has gone,
    ///   after the button's action (not after `dismiss()`).
    @discardableResult
    public func present<Content: View>(
        onDismissed: (() -> Void)? = nil,
        @ViewBuilder _ content: () -> Content
    ) -> Bool {
        guard window == nil, let scene = Self.activeScene else { return false }
        presentation += 1
        let id = presentation
        let appWindow = scene.keyWindow ?? scene.windows.first { !$0.isHidden && $0.windowLevel == .normal }

        let root = MomentWindowRoot(
            content: content(),
            dismissal: MomentDismissal { [weak self] action in self?.finish(id, action: action) }
        )
        let host = UIHostingController(rootView: root)
        host.view.backgroundColor = .clear
        // VoiceOver stays in the moment while it is up.
        host.view.accessibilityViewIsModal = true

        let window = UIWindow(windowScene: scene)
        window.windowLevel = MomentPresenterMetrics.windowLevel
        window.backgroundColor = .clear
        window.overrideUserInterfaceStyle = Self.interfaceStyle(of: appWindow)
        window.tintColor = UIColor(DesignKitTheme.accent)
        window.rootViewController = host
        // Visible without becoming key: the app's window keeps the keyboard and key status.
        window.isHidden = false

        self.window = window
        self.onDismissed = onDismissed
        return true
    }

    /// Removes the moment at once, without its exit (e.g. the app went to the background).
    /// Neither a button's action nor `onDismissed` runs: the caller knows the moment went.
    public func dismiss() {
        guard window != nil else { return }
        tearDown()
    }

    /// The moment has played its exit: the window goes, then the action, then `onDismissed`.
    private func finish(_ id: Int, action: (() -> Void)?) {
        guard id == presentation, window != nil else { return }
        // Out of the SwiftUI update of the window being removed.
        Task { @MainActor [weak self] in
            guard let self, id == self.presentation, self.window != nil else { return }
            let dismissed = self.onDismissed
            self.tearDown()
            action?()
            dismissed?()
        }
    }

    private func tearDown() {
        window?.isHidden = true
        window?.rootViewController = nil
        window = nil
        onDismissed = nil
        // VoiceOver goes back to the app.
        UIAccessibility.post(notification: .screenChanged, argument: nil)
    }

    /// The foreground-active window scene, the one with a key window first (iPad, several
    /// windows).
    private static var activeScene: UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
        return scenes.first { $0.keyWindow != nil } ?? scenes.first
    }

    /// The app's own light or dark choice: its window's, else its root controller's (where
    /// SwiftUI's `preferredColorScheme` may put it); unspecified follows the system, as the app.
    private static func interfaceStyle(of window: UIWindow?) -> UIUserInterfaceStyle {
        guard let window else { return .unspecified }
        if window.overrideUserInterfaceStyle != .unspecified { return window.overrideUserInterfaceStyle }
        return window.rootViewController?.overrideUserInterfaceStyle ?? .unspecified
    }
}

enum MomentPresenterMetrics {
    /// Above the app's windows (`.normal`), below system alerts (an app's lock screen in a
    /// window at `.alert + 1` covers a moment).
    static let windowLevel = UIWindow.Level.alert - 1
}

/// The moment in the presenter's window: its way out and the app's accent.
private struct MomentWindowRoot<Content: View>: View {
    let content: Content
    let dismissal: MomentDismissal

    var body: some View {
        content
            .environment(\.momentDismissal, dismissal)
            .tint(DesignKitTheme.accent)
    }
}
