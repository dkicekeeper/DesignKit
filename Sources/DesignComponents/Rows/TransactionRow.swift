//
//  TransactionRow.swift
//  DesignKit
//
//  A money movement in a list (2.9.0): its icon (a category or a merchant's logo, a badge on the
//  corner for a repeating one), what it was (the category, its details, the account, a note) or,
//  for a transfer, from which account to which, and the amounts on the trailing edge (the amount,
//  its equivalent in the account's currency, or a transfer's two legs). A future one is dimmed.
//  Ported from Tenra's TransactionCardView and its pieces (TransactionIconView, TransactionInfoView,
//  TransferAccountInfo, RegularAccountInfo, TransferAmountView); the transaction model, the
//  accounts lookup and the amount maths stay in Tenra, which passes what to show.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// A transaction's row.
///
/// ```swift
/// // A purchase
/// TransactionRow(
///     .entry(title: "Groceries", details: "Vegetables, Bread",
///            account: .init(name: "Kaspi Gold", icon: .brandService("kaspi.kz"))),
///     note: "Magnum",
///     icon: .sfSymbol("cart.fill"), iconTint: .monochrome(.orange), iconBackground: AppColors.pale(.orange),
///     amounts: [.init(18_500, currency: "KZT", prefix: "-", color: AppColors.Text.primary)],
///     accessibilityLabel: "Groceries, 18 500 tenge, Kaspi Gold"
/// )
/// // A transfer: from → to, both legs
/// TransactionRow(
///     .transfer(from: .init(name: "Kaspi Gold", icon: …), to: .init(name: "Deposit", icon: …)),
///     icon: .sfSymbol("arrow.left.arrow.right"), iconTint: .monochrome(AppColors.transfer),
///     iconBackground: AppColors.pale(AppColors.transfer),
///     amounts: [.init(100_000, currency: "KZT", prefix: "-", color: .primary),
///               .init(100_000, currency: "KZT", prefix: "+", color: AppColors.income)],
///     accessibilityLabel: "Transfer, 100 000 tenge, from Kaspi Gold to Deposit"
/// )
/// ```
///
/// Padding: vertical `AppSpacing.sm` (a row in a card). Make it tappable at the call site.
public struct TransactionRow: View {
    /// An account the row names: its logo and name; a deleted account keeps its name, in italic,
    /// without a logo.
    public struct Account: Hashable {
        public let name: String
        public let icon: IconSource?
        public let isDeleted: Bool

        public init(name: String, icon: IconSource?, isDeleted: Bool = false) {
            self.name = name
            self.icon = icon
            self.isDeleted = isDeleted
        }

        /// A deleted account: its name only.
        public static func deleted(_ name: String) -> Account {
            Account(name: name, icon: nil, isDeleted: true)
        }
    }

    /// What the row says on the left.
    public enum Subject: Hashable {
        /// A purchase or an income: the title (the category, `h4`), a line of details (its
        /// subcategories) and the account (logo and name, secondary).
        case entry(title: String, details: String? = nil, account: Account? = nil)
        /// A transfer: the source on top, an arrow and the target under it, at the amount's size.
        case transfer(from: Account?, to: Account?)
    }

    /// One amount on the trailing edge.
    public struct Amount: Hashable {
        public let amount: Double
        public let currency: String
        /// "+", "-" or "".
        public let prefix: String
        public let color: Color

        public init(_ amount: Double, currency: String, prefix: String = "", color: Color = AppColors.Text.primary) {
            self.amount = amount
            self.currency = currency
            self.prefix = prefix
            self.color = color
        }
    }

    let subject: Subject
    let note: String?
    let icon: IconSource?
    let iconTint: IconTint
    let iconBackground: Color?
    let badgeSystemImage: String?
    let amounts: [Amount]
    let isPending: Bool
    let accessibilityLabel: String
    let transitionSourceID: String?
    let transitionNamespace: Namespace.ID?

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// - Parameters:
    ///   - note: Under everything, in caption secondary (the description).
    ///   - icon, iconTint, iconBackground: The 44 pt round icon: a category symbol in its colour,
    ///     or a merchant's logo (`.original`).
    ///   - badgeSystemImage: A small symbol on the icon's top-leading corner ("arrow.clockwise"
    ///     for a repeating payment still to come).
    ///   - amounts: Top to bottom on the trailing edge: the amount and its equivalent (the second
    ///     at 70% of its colour), or a transfer's outgoing and incoming legs.
    ///   - isPending: A future transaction: the row is dimmed.
    ///   - transitionSourceID, transitionNamespace: Make the icon the source of a zoom transition.
    public init(
        _ subject: Subject,
        note: String? = nil,
        icon: IconSource?,
        iconTint: IconTint,
        iconBackground: Color?,
        badgeSystemImage: String? = nil,
        amounts: [Amount],
        isPending: Bool = false,
        accessibilityLabel: String,
        transitionSourceID: String? = nil,
        transitionNamespace: Namespace.ID? = nil
    ) {
        self.subject = subject
        self.note = note
        self.icon = icon
        self.iconTint = iconTint
        self.iconBackground = iconBackground
        self.badgeSystemImage = badgeSystemImage
        self.amounts = amounts
        self.isPending = isPending
        self.accessibilityLabel = accessibilityLabel
        self.transitionSourceID = transitionSourceID
        self.transitionNamespace = transitionNamespace
    }

    public var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                // At accessibility sizes the amounts go under the text, leading (3.0.0): beside
                // it they left the title so little room that words broke in the middle.
                HStack(alignment: .top, spacing: AppSpacing.md) {
                    iconView
                        .matchedTransitionSourceIfPresent(id: transitionSourceID, namespace: transitionNamespace)
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        info
                        amountLines(alignment: .leading)
                    }
                    Spacer(minLength: 0)
                }
            } else {
                HStack(spacing: AppSpacing.md) {
                    iconView
                        .matchedTransitionSourceIfPresent(id: transitionSourceID, namespace: transitionNamespace)

                    info

                    Spacer()

                    amountLines(alignment: .trailing)
                }
            }
        }
        .padding(.vertical, AppSpacing.sm)
        .futureTransactionStyle(isFuture: isPending)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(verbatim: accessibilityLabel))
    }

    private var isTransfer: Bool {
        if case .transfer = subject { return true }
        return false
    }

    /// The amounts, top to bottom.
    private func amountLines(alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: AppSpacing.xs) {
            ForEach(Array(amounts.enumerated()), id: \.offset) { index, line in
                FormattedAmountText(
                    amount: line.amount,
                    currency: line.currency,
                    prefix: line.prefix,
                    // An entry's second line is its equivalent, a shade lighter; a
                    // transfer's legs are both full colour.
                    color: index > 0 && !isTransfer ? line.color.opacity(TransactionRowMetrics.equivalentOpacity) : line.color
                )
            }
        }
    }

    // MARK: Icon

    private var iconView: some View {
        ZStack(alignment: .topLeading) {
            Icon(
                source: icon,
                style: .circle(size: AppIconSize.Tile.sm, tint: iconTint, backgroundColor: iconBackground)
            )
            if let badgeSystemImage {
                Image(systemName: badgeSystemImage)
                    .font(.system(size: AppIconSize.sm))
                    .foregroundStyle(.primary)
                    .padding(AppSpacing.xs)
                    .background(AppColors.bgBase)
                    .clipShape(Circle())
                    .offset(x: -TransactionRowMetrics.badgeOffset, y: -TransactionRowMetrics.badgeOffset)
            }
        }
    }

    // MARK: Info

    private var info: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            switch subject {
            case .entry(let title, let details, let account):
                Text(verbatim: title)
                    .font(AppTypography.h4)
                if let details, !details.isEmpty {
                    Text(verbatim: details)
                        .font(AppTypography.bodySmall)
                        .foregroundStyle(.primary)
                }
                if let account {
                    entryAccount(account)
                }
            case .transfer(let from, let to):
                // The accounts are the headline (no "Transfer" title), at the amount's size.
                transferAccounts(from: from, to: to)
            }

            if let note, !note.isEmpty {
                Text(verbatim: note)
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func entryAccount(_ account: Account) -> some View {
        if account.isDeleted {
            Text(verbatim: account.name)
                .font(AppTypography.bodySmall)
                .foregroundStyle(AppColors.Text.secondary)
                .italic()
        } else {
            HStack(spacing: AppSpacing.xs) {
                Icon(source: account.icon, size: AppIconSize.sm)
                Text(verbatim: account.name)
                    .font(AppTypography.bodySmall)
                    .foregroundStyle(AppColors.Text.secondary)
            }
        }
    }

    private func transferAccounts(from: Account?, to: Account?) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            if let from {
                HStack(spacing: AppSpacing.xs) {
                    if !from.isDeleted {
                        Icon(source: from.icon, size: AppIconSize.sm)
                    }
                    transferName(from)
                }
            }

            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "arrow.turn.down.right")
                    .font(.system(size: AppIconSize.sm))
                    .foregroundStyle(AppColors.Text.secondary)

                if let to {
                    if !to.isDeleted {
                        Icon(source: to.icon, size: AppIconSize.sm)
                    }
                    transferName(to)
                }
            }
        }
    }

    private func transferName(_ account: Account) -> some View {
        Text(verbatim: account.name)
            .font(AppTypography.body)
            .fontWeight(.semibold)
            .foregroundStyle(account.isDeleted ? AnyShapeStyle(.secondary) : AnyShapeStyle(.primary))
            .italic(account.isDeleted)
            .lineLimit(1)
    }
}

enum TransactionRowMetrics {
    /// The equivalent's shade of the amount's colour.
    static let equivalentOpacity: Double = 0.7
    /// How far the badge sits out over the icon's corner.
    static let badgeOffset: CGFloat = 8
}

// MARK: - Skeleton

/// Placeholder of a `TransactionRow`: the round icon, the title and the account, the amount.
public struct TransactionRowSkeleton: View {
    let showsDetails: Bool

    public init(showsDetails: Bool = true) {
        self.showsDetails = showsDetails
    }

    public var body: some View {
        HStack(spacing: AppSpacing.md) {
            Skeleton.circle(AppIconSize.Tile.sm)
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                SkeletonText(AppTypography.h4, width: 120)
                if showsDetails {
                    SkeletonText(AppTypography.bodySmall, width: 90)
                }
            }
            Spacer()
            SkeletonText(AppTypography.body, width: 80)
        }
        .padding(.vertical, AppSpacing.sm)
        .shimmer()
        .skeletonLoadingLabel()
    }
}
