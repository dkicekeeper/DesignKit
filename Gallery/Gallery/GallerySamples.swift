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
