//
//  LimitProgress.swift
//  DesignKit
//
//  How much of a limit is used: the input of the progress ring around ProgressRingRow's and
//  ProgressRingTile's icon. Tenra maps its BudgetProgress onto it.
//

import Foundation

/// A value spent against a limit (a budget, a quota).
///
/// ```swift
/// LimitProgress(spent: 185_000, limit: 250_000)   // 74%, within the limit
/// ```
public struct LimitProgress: Equatable, Sendable {
    public let spent: Double
    public let limit: Double
    /// `spent` as a share of `limit`, 0…100+ (not clamped).
    public let percentage: Double
    public let isOverLimit: Bool

    /// - Parameters:
    ///   - percentage: `spent / limit × 100` (0 for a zero limit) when not given.
    ///   - isOverLimit: `spent > limit` when not given.
    public init(spent: Double, limit: Double, percentage: Double? = nil, isOverLimit: Bool? = nil) {
        self.spent = spent
        self.limit = limit
        self.percentage = percentage ?? (limit > 0 ? (spent / limit) * 100 : 0)
        self.isOverLimit = isOverLimit ?? (spent > limit)
    }
}
