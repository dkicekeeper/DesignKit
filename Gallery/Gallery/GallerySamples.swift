//
//  GallerySamples.swift
//  DesignKit Gallery
//
//  Demo data the component pages share: a spending breakdown, category tiles, sixteen months
//  of income, spending and distance.
//

import SwiftUI
import DesignTokens
import DesignComponents

enum GallerySamples {
    /// Spending by category, shares adding up to 100.
    static let slices: [DonutSlice] = [
        DonutSlice(id: "food", amount: 42_000, color: AppColors.accent, label: "Food", percentage: 42),
        DonutSlice(id: "rent", amount: 30_000, color: AppColors.success, label: "Rent", percentage: 30),
        DonutSlice(id: "fun", amount: 18_000, color: AppColors.warning, label: "Fun", percentage: 18),
        DonutSlice(id: "misc", amount: 10_000, color: AppColors.transfer, label: "Misc", percentage: 10),
    ]

    /// Category tiles: within the limit, over it, no limit.
    static let tileItems: [ProgressRingTileGridItem] = [
        ProgressRingTileGridItem(id: "food", title: "Food", systemImage: "fork.knife", color: .orange,
                                 progress: LimitProgress(spent: 185_000, limit: 250_000),
                                 amount: 185_000, limit: 250_000),
        ProgressRingTileGridItem(id: "shopping", title: "Shopping", systemImage: "bag.fill", color: AppColors.accent,
                                 progress: LimitProgress(spent: 132_000, limit: 100_000),
                                 amount: 132_000, limit: 100_000),
        ProgressRingTileGridItem(id: "transport", title: "Transport", systemImage: "car.fill", color: .blue,
                                 amount: 24_500),
        ProgressRingTileGridItem(id: "home", title: "Home", systemImage: "house.fill", color: .green,
                                 amount: 210_000),
    ]

    static let income = ChartSeries<ChartValuePoint>.keyed(
        "income", name: "Income", coloring: .solid(AppColors.success))
    static let expenses = ChartSeries<ChartValuePoint>.keyed(
        "expenses", name: "Expenses", coloring: .solid(AppColors.destructive))
    static let netFlow = ChartSeries<ChartValuePoint>(
        id: "net", name: "Net", coloring: .signed(positive: AppColors.success, negative: AppColors.destructive),
        baseline: .signed
    ) { $0["income"] - $0["expenses"] }
    static let distance = ChartSeries<ChartValuePoint>.keyed(
        "km", name: "Distance", coloring: .solid(AppColors.accent))

    /// Sixteen months ending this month.
    static let months: [ChartValuePoint] = {
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .month, value: -15, to: calendar.startOfDay(for: .now)) ?? .now
        let axis = DateFormatter()
        axis.dateFormat = "MMM"
        let title = DateFormatter()
        title.dateFormat = "LLLL yyyy"
        let incomes: [Double] = [420, 455, 430, 510, 480, 495, 520, 470, 530, 560, 540, 575, 590, 610, 600, 620]
        let spending: [Double] = [380, 410, 470, 450, 520, 430, 480, 500, 460, 590, 510, 540, 560, 580, 520, 610]
        let km: [Double] = [18, 25, 31, 22, 40, 52, 47, 38, 55, 61, 44, 58, 49, 66, 57, 60]
        return (0..<16).map { index in
            let date = calendar.date(byAdding: .month, value: index, to: start) ?? start
            return ChartValuePoint(
                label: "m\(index)",
                axisLabel: axis.string(from: date).uppercased(),
                title: title.string(from: date),
                date: date,
                values: ["income": incomes[index] * 1_000, "expenses": spending[index] * 1_000, "km": km[index]]
            )
        }
    }()

    /// `count` months ending this month, for the trend charts' pages (8.3.0): the last sixteen
    /// are `months`, earlier years repeat them a little lower. `inProgress`: this month is not
    /// over yet, and only ten days of it are in; `<key>Forecast` is where it is heading. Each
    /// month also has `<key>LastYear` (a year before, a little lower) and spending by category
    /// (`food`, `home`, `transport`, `fun`) for stacked bars.
    static func monthSeries(_ count: Int, inProgress: Bool) -> [ChartValuePoint] {
        let calendar = Calendar.current
        let thisMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: .now)) ?? .now
        let axis = DateFormatter()
        axis.dateFormat = "MMM"
        let title = DateFormatter()
        title.dateFormat = "LLLL yyyy"
        let base = months
        return (0..<count).map { index in
            let monthsAgo = count - 1 - index
            let sample = base[base.count - 1 - monthsAgo % base.count]
            let isCurrent = inProgress && monthsAgo == 0
            let yearScale = pow(0.92, Double(monthsAgo / base.count))
            let scale = yearScale * (isCurrent ? 0.35 : 1)
            let date = calendar.date(byAdding: .month, value: -monthsAgo, to: thisMonth) ?? thisMonth
            var values = sample.values.mapValues { $0 * scale }
            for (key, value) in sample.values {
                values["\(key)LastYear"] = value * yearScale * 0.9
                if isCurrent { values["\(key)Forecast"] = value * yearScale * 1.04 }
            }
            let spending = values["expenses"] ?? 0
            let shares: [(String, Double)] = [("food", 0.38), ("home", 0.30), ("transport", 0.18), ("fun", 0.14)]
            for (offset, share) in shares.enumerated() {
                // A little different each month, the four adding up to the month's spending.
                let wobble = 1 + 0.12 * sin(Double(index * 3 + offset))
                values[share.0] = (spending * share.1 * wobble).rounded()
            }
            return ChartValuePoint(
                label: "y\(index)",
                axisLabel: axis.string(from: date).uppercased(),
                title: title.string(from: date),
                date: date,
                isPartial: isCurrent,
                values: values
            )
        }
    }
}

extension GallerySamples {
    /// Spending by category, for stacked bars.
    static let categories: [ChartSeries<ChartValuePoint>] = [
        .keyed("food", name: "Food", coloring: .solid(AppColors.Palette.orange.color)),
        .keyed("home", name: "Home", coloring: .solid(AppColors.Palette.blue.color)),
        .keyed("transport", name: "Transport", coloring: .solid(AppColors.Palette.teal.color)),
        .keyed("fun", name: "Fun", coloring: .solid(AppColors.Palette.purple.color)),
    ]

    /// Spending a day for `days` days up to today: busier at the weekend and at the start of a
    /// month, nothing on some days; the same on every run.
    static func spendingByDay(days: Int = 371, today: Date = .now, calendar: Calendar = .current) -> [Date: Double] {
        let last = calendar.startOfDay(for: today)
        var result = [Date: Double]()
        var seed: UInt64 = 42
        for back in 0..<days {
            guard let day = calendar.date(byAdding: .day, value: -back, to: last) else { continue }
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            let noise = Double(seed >> 33) / Double(UInt32.max)
            let weekday = calendar.component(.weekday, from: day)
            let weekend = weekday == 1 || weekday == 7 ? 1.8 : 1
            let monthStart = calendar.component(.day, from: day) <= 3 ? 2.2 : 1
            guard noise > 0.18 else { continue }
            result[day] = (4_000 + 14_000 * noise) * weekend * monthStart
        }
        return result
    }
}

// MARK: - Photos

/// A stand-in photo: a gradient with a symbol, the same on every run (snapshots), so the photo
/// components have something to show without bundled pictures.
struct GalleryPhoto: Identifiable, Hashable {
    let id: Int
    let colors: [Color]
    let symbol: String
    let caption: String

    static let samples: [GalleryPhoto] = [
        GalleryPhoto(id: 0, colors: [.teal, .blue], symbol: "mountain.2.fill", caption: "Big Almaty Lake"),
        GalleryPhoto(id: 1, colors: [.orange, .pink], symbol: "sun.horizon.fill", caption: "Kapchagay at dawn"),
        GalleryPhoto(id: 2, colors: [.green, .mint], symbol: "tree.fill", caption: "Medeu trail"),
        GalleryPhoto(id: 3, colors: [.indigo, .purple], symbol: "moon.stars.fill", caption: "Camp at night"),
        GalleryPhoto(id: 4, colors: [.cyan, .teal], symbol: "fish.fill", caption: "First catch"),
        GalleryPhoto(id: 5, colors: [.yellow, .orange], symbol: "tent.fill", caption: "Base camp"),
    ]
}

/// A `GalleryPhoto` drawn as a picture: filling its frame (a tile), or a 4:3 picture fitted in it
/// (the viewer).
struct GalleryPhotoView: View {
    let photo: GalleryPhoto
    var fits = false

    var body: some View {
        if fits {
            picture.aspectRatio(4.0 / 3.0, contentMode: .fit)
        } else {
            picture
        }
    }

    private var picture: some View {
        LinearGradient(colors: photo.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            .overlay {
                Image(systemName: photo.symbol)
                    .font(.system(size: 28))
                    .foregroundStyle(.white.opacity(0.85))
            }
    }
}
