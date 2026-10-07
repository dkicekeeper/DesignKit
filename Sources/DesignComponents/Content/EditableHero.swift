//
//  EditableHero.swift
//  DesignKit
//
//  The top of an edit sheet: a large glass icon that opens the icon picker, the name typed
//  in place with the animated title input, and, when the entity has one, an amount with its
//  currency. Ported from Tenra's EditableHeroSection (accounts, subscriptions, categories);
//  it presents DesignKit's IconPicker and CurrencyList, so nothing of the app is needed.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// An editable hero: icon, name and an optional amount.
///
/// ```swift
/// EditableHero(icon: $icon, title: $name, titlePlaceholder: "Account name",
///              amount: $balance, currency: $currency, options: .amountAndCurrency)
/// EditableHero(icon: $icon, title: $name, titlePlaceholder: "Category name",
///              iconTint: color, options: .symbolsOnly)
/// ```
///
/// The currency chip pushes `CurrencyList`, so put the hero in a `NavigationStack`.
public struct EditableHero: View {
    /// What the hero shows besides the icon and the name.
    public struct Options: Sendable {
        /// The amount input under the name.
        public var showsAmount: Bool
        /// The currency chip under the amount.
        public var showsCurrency: Bool
        /// The icon picker's logos tab.
        public var allowsLogos: Bool

        public init(showsAmount: Bool = false, showsCurrency: Bool = false, allowsLogos: Bool = true) {
            self.showsAmount = showsAmount
            self.showsCurrency = showsCurrency
            self.allowsLogos = allowsLogos
        }

        /// An amount with its currency (an account, a subscription).
        public static let amountAndCurrency = Options(showsAmount: true, showsCurrency: true)
        /// Only the icon and the name, symbols only (a category).
        public static let symbolsOnly = Options(allowsLogos: false)
    }

    @Binding var icon: IconSource?
    @Binding var title: String
    @Binding var amount: String
    @Binding var currency: String
    let titlePlaceholder: String
    let iconTint: Color?
    let options: Options
    let autoFocusTitle: Bool

    @State private var showsIconPicker = false
    @State private var iconScale: CGFloat = AppAnimation.heroHiddenScale
    @State private var iconOpacity: Double = 0

    /// - Parameters:
    ///   - iconTint: Draws the icon as a symbol in this colour on glass (a category); without
    ///     it the icon keeps its own colours (a logo, an account).
    ///   - autoFocusTitle: Focuses the name on first appear.
    public init(
        icon: Binding<IconSource?>,
        title: Binding<String>,
        titlePlaceholder: String,
        amount: Binding<String> = .constant(""),
        currency: Binding<String> = .constant("USD"),
        iconTint: Color? = nil,
        options: Options = Options(),
        autoFocusTitle: Bool = false
    ) {
        self._icon = icon
        self._title = title
        self._amount = amount
        self._currency = currency
        self.titlePlaceholder = titlePlaceholder
        self.iconTint = iconTint
        self.options = options
        self.autoFocusTitle = autoFocusTitle
    }

    public var body: some View {
        VStack(spacing: AppSpacing.lg) {
            heroIcon
                .scaleEffect(iconScale)
                .opacity(iconOpacity)
                .onAppear {
                    withAnimation(AppAnimation.heroEntranceAnimation) {
                        iconScale = 1.0
                        iconOpacity = 1.0
                    }
                }

            AnimatedTitleInput(text: $title, placeholder: titlePlaceholder, autoFocus: autoFocusTitle)
                .screenPadding()

            if options.showsAmount {
                amountView
            }
        }
        .padding(.vertical, AppSpacing.lg)
        .sheet(isPresented: $showsIconPicker) {
            IconPicker(selection: $icon, allowsLogos: options.allowsLogos)
        }
    }

    private var heroIcon: some View {
        Button {
            HapticManager.light()
            showsIconPicker = true
        } label: {
            if let iconTint {
                IconView(source: icon ?? .sfSymbol("star.fill"), style: .glassHero(tint: .monochrome(iconTint)))
            } else {
                IconView(source: icon, style: .glassHero())
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "common.changeIcon", defaultValue: "Change icon"))
    }

    private var amountView: some View {
        VStack(spacing: AppSpacing.sm) {
            AmountInput(amount: $amount, baseFontSize: 48, placeholderColor: AppColors.Text.tertiary)
                .padding(.horizontal, AppSpacing.lg)

            if options.showsCurrency {
                NavigationLink {
                    EditableHeroCurrencyScreen(currency: $currency)
                } label: {
                    HStack(spacing: AppSpacing.sm) {
                        Text(verbatim: Formatting.currencySymbol(for: currency))
                        Text(verbatim: currency)
                            .font(AppTypography.bodySmall)
                        Image(systemName: "chevron.right")
                            .font(.system(size: AppIconSize.sm))
                    }
                    .filterChipStyle(isSelected: false)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// The currency list the hero's chip pushes; a pick goes back.
private struct EditableHeroCurrencyScreen: View {
    @Binding var currency: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        CurrencyList(selection: currency) { code in
            currency = code
            dismiss()
        }
        .navigationTitle(String(localized: "currency.title", defaultValue: "Currency"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
