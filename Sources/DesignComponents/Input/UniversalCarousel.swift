//
//  UniversalCarousel.swift
//  Tenra
//
//  Created: 2026-02-16
//  Universal horizontal carousel component
//
//  Consolidates 10+ carousel implementations into a single, configurable component
//  with Design System integration and centralized localization.
//
//  Usage:
//  ```swift
//  // Simple carousel
//  UniversalCarousel(config: .standard) {
//      ForEach(items) { item in
//          ItemView(item: item)
//      }
//  }
//
//  // With auto-scroll support
//  UniversalCarousel(
//      config: .standard,
//      scrollToId: $selectedItemId
//  ) {
//      ForEach(items) { item in
//          ItemView(item: item)
//              .id(item.id)
//      }
//  }
//  ```
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Universal horizontal carousel component
/// Provides consistent scrolling behavior across the app with configurable presets
public struct UniversalCarousel<Content: View>: View {
    // MARK: - Properties

    /// Configuration preset (standard, compact, filter, cards, csvPreview)
    let config: CarouselConfiguration

    /// Content builder for carousel items
    @ViewBuilder let content: () -> Content

    /// Optional binding for auto-scroll to specific item ID
    /// When set, the carousel will automatically scroll to center the item with this ID
    let scrollToId: Binding<AnyHashable?>?

    /// Optional VoiceOver label for the carousel container.
    ///
    /// When provided, VoiceOver announces this label before the individual child elements,
    /// giving screen-reader users context about what the carousel contains
    /// (e.g. `"Period filter"`, `"Account selector"`, `"CSV column preview"`).
    ///
    /// When `nil` (default), VoiceOver traverses child elements directly without a
    /// container announcement — suitable when the surrounding UI already provides context.
    let accessibilityLabel: String?

    // MARK: - Initializer

    /// Creates a universal carousel with specified configuration
    /// - Parameters:
    ///   - config: Configuration preset (default: .standard)
    ///   - scrollToId: Optional binding for auto-scroll to item ID
    ///   - accessibilityLabel: Optional VoiceOver container label. Pass a localised string when
    ///     the carousel has semantic meaning (e.g. "Period filter", "Account selector").
    ///     Omit (default `nil`) when surrounding UI already conveys context.
    ///   - content: ViewBuilder for carousel items
    public init(
        config: CarouselConfiguration = .standard,
        scrollToId: Binding<AnyHashable?>? = nil,
        accessibilityLabel: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.config = config
        self.scrollToId = scrollToId
        self.accessibilityLabel = accessibilityLabel
        self.content = content
    }

    // MARK: - Body

    public var body: some View {
        if let scrollBinding = scrollToId {
            // ScrollViewReader version for auto-scroll support
            ScrollViewReader { proxy in
                scrollViewContent
                    .onAppear {
                        // Defer to the next runloop tick — `proxy.scrollTo` is a no-op
                        // before the scroll view has measured its content, which happens
                        // *after* the synchronous onAppear closure on first appear.
                        DispatchQueue.main.async {
                            guard let id = scrollBinding.wrappedValue else { return }
                            proxy.scrollTo(id, anchor: .center)
                        }
                    }
                    .onChange(of: scrollBinding.wrappedValue) { _, newId in
                        guard let newId else { return }
                        withAnimation(config.scrollAnimation) {
                            proxy.scrollTo(newId, anchor: .center)
                        }
                    }
            }
        } else {
            // Standard version without auto-scroll
            scrollViewContent
        }
    }

    // MARK: - Private Views

    /// Base ScrollView without an accessibility container label.
    @ViewBuilder
    private var baseScrollView: some View {
        switch config.snapBehavior {
        case .viewAligned:
            ScrollView(.horizontal, showsIndicators: config.showsIndicators) {
                HStack(spacing: config.spacing) {
                    content()
                }
                .padding(.horizontal, config.horizontalPadding)
                .padding(.vertical, config.verticalPadding)
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollClipDisabled(config.clipDisabled)

        case .none:
            ScrollView(.horizontal, showsIndicators: config.showsIndicators) {
                HStack(spacing: config.spacing) {
                    content()
                }
                .padding(.horizontal, config.horizontalPadding)
                .padding(.vertical, config.verticalPadding)
            }
            .scrollClipDisabled(config.clipDisabled)
        }
    }

    /// ScrollView with optional VoiceOver container label applied.
    ///
    /// When `accessibilityLabel` is set the scroll container is announced by VoiceOver
    /// so users understand what type of items the carousel holds before swiping through them.
    @ViewBuilder
    private var scrollViewContent: some View {
        if let label = accessibilityLabel {
            baseScrollView
                .accessibilityLabel(label)
        } else {
            baseScrollView
        }
    }
}

// MARK: - Item transition

public extension View {
    /// A card in a carousel that dims to 75% and shrinks to 95% as it scrolls off, and comes
    /// back as it scrolls in (Tenra's accounts carousel). Pass `false` for a short carousel
    /// that never scrolls, where the effect would only flicker at the edges.
    ///
    /// ```swift
    /// UniversalCarousel(config: .cards) {
    ///     ForEach(accounts) { BalanceCard(…).carouselItemTransition(isEnabled: accounts.count >= 3) }
    /// }
    /// ```
    func carouselItemTransition(isEnabled: Bool = true) -> some View {
        modifier(CarouselItemTransition(isEnabled: isEnabled))
    }
}

private struct CarouselItemTransition: ViewModifier {
    let isEnabled: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if isEnabled {
            content.scrollTransition(.interactive) { content, phase in
                content
                    .opacity(phase.isIdentity ? 1 : 0.75)
                    .scaleEffect(phase.isIdentity ? 1 : 0.95)
            }
        } else {
            content
        }
    }
}
