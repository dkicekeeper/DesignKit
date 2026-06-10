//
//  DonutChart.swift
//  Tenra
//
//  Phase 43 (chart merge): Unified donut (ring) chart component.
//  Replaces two structurally identical components:
//  - CategoryBreakdownChart   (multi-color sectors, compact/full modes, annotations)
//  - SubcategoryBreakdownChart (monochromatic opacity-stepped sectors)
//
//  Behavioral differences are resolved at the call site via `DonutSlice` factory methods.
//

import SwiftUI
import DesignTokens
import DesignSupport
import Charts

// MARK: - DonutSlice

/// A single sector in a `DonutChart`.
public struct DonutSlice: Identifiable {
    public let id: String
    let amount: Double
    let color: Color
    /// Display label (used for VoiceOver / external lists).
    let label: String
    /// 0–100 percentage, used for in-sector annotation (shown when > 10%).
    let percentage: Double

    public init(id: String, amount: Double, color: Color, label: String, percentage: Double) {
        self.id = id
        self.amount = amount
        self.color = color
        self.label = label
        self.percentage = percentage
    }
}

// (DesignKit drops Tenra's `DonutSlice.from([CategoryBreakdownItem])` /
//  `from([SubcategoryBreakdownItem])` domain converters — build `[DonutSlice]` directly.)

// MARK: - DonutChart

/// Unified donut (ring) chart for any `DonutSlice` series.
///
/// Supports compact sparkline mode (60 pt) and full detail mode (200 pt).
/// Appearance and update animations are built in.
///
/// Usage:
/// ```swift
/// // Category breakdown (multi-color, with overlay annotations)
/// DonutChart(slices: DonutSlice.from(items))
///
/// // Subcategory breakdown (monochromatic, no annotations)
/// DonutChart(slices: DonutSlice.from(subcategories, baseColor: color),
///            showAnnotations: false)
///
/// // Compact sparkline
/// DonutChart(slices: DonutSlice.from(items), mode: .compact)
///
/// // Full mode with center label (total amount, selected slice, etc.)
/// DonutChart(slices: DonutSlice.from(items)) {
///     VStack(spacing: 2) {
///         Text("Total").font(.caption).foregroundStyle(.secondary)
///         Text("125 000 ₸").font(.title3.weight(.semibold))
///     }
/// }
/// ```
public struct DonutChart<CenterContent: View>: View {
    let slices: [DonutSlice]
    var mode: ChartDisplayMode = .full
    /// Show percentage labels inside sectors larger than 10 % (full mode only).
    var showAnnotations: Bool = true
    /// Optional content rendered in the donut hole (full mode only).
    @ViewBuilder var centerContent: () -> CenterContent

    private var isCompact: Bool { mode == .compact }
    /// Chart ring height: 60 compact / 200 full.
    private var ringHeight: CGFloat { isCompact ? 60 : 200 }

    /// Entrance reveal progress (0 → 1). Drives a trimmed-arc mask that sweeps the
    /// ring into view around the circumference, so the donut appears to "draw itself".
    @State private var drawProgress: CGFloat = 0

    // MARK: Body

    public var body: some View {
        // Compact mini-charts skip the entrance reveal — they render inside scroll feeds
        // where `LazyVStack` realises sections during scroll; firing N concurrent
        // entrance animations at materialisation cost frames. Full mode keeps it.
        if isCompact {
            compactChart
        } else {
            fullChart
        }
    }

    /// Adaptive corner radius for sectors.
    /// Sectors smaller than 5 % get a tighter radius (4 pt) so they don't visually
    /// collapse into a circle; larger sectors keep the original 12 pt rounding.
    private func cornerRadius(for percentage: Double) -> CGFloat {
        percentage < 5 ? AppRadius.xs : AppRadius.md
    }

    // MARK: - Compact chart

    private var compactChart: some View {
        Chart(slices) { slice in
            SectorMark(
                angle: .value("Amount", slice.amount),
                innerRadius: .ratio(0.6),
                angularInset: 1
            )
            .cornerRadius(cornerRadius(for: slice.percentage))
            .foregroundStyle(slice.color)
        }
        .frame(height: 60)
        .chartLegend(.hidden)
    }

    // MARK: - Full chart

    private var fullChart: some View {
        ZStack {
            Chart(slices) { slice in
                SectorMark(
                    angle: .value("Amount", slice.amount),
                    innerRadius: .ratio(0.5),
                    angularInset: 2
                )
                .cornerRadius(cornerRadius(for: slice.percentage))
                .foregroundStyle(slice.color)
                .annotation(position: .overlay) {
                    if showAnnotations && slice.percentage > 10 {
                        Text(String(format: "%.0f%%", slice.percentage))
                            .font(AppTypography.bodyEmphasis)
                            .foregroundStyle(.white)
                    }
                }
            }
            .animation(AppAnimation.chartUpdateAnimation, value: slices.count)
            .chartLegend(.hidden)
            // Reveal the ring by sweeping a trimmed arc around the circumference.
            .mask { sweepMask }

            centerContent()
                .allowsHitTesting(false)
        }
        .frame(height: ringHeight)
        .onAppear {
            drawProgress = 0
            withAnimation(.easeOut(duration: 0.7)) { drawProgress = 1 }
        }
    }

    /// A clockwise-from-top trimmed-circle stroke whose thickness spans the whole
    /// radius — used as a `.mask` so animating `drawProgress` 0→1 wipes the donut
    /// into view around its circumference.
    private var sweepMask: some View {
        GeometryReader { geo in
            let d = min(geo.size.width, geo.size.height)
            Circle()
                .trim(from: 0, to: drawProgress)
                .stroke(style: StrokeStyle(lineWidth: d / 2, lineCap: .butt))
                .frame(width: d / 2, height: d / 2)
                .rotationEffect(.degrees(-90))
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
    }
}

// MARK: - Convenience init (no center content)

public extension DonutChart where CenterContent == EmptyView {
    /// Convenience initializer for the common case of a donut without a center label.
    /// Preserves source-compatibility with existing call sites.
    public init(
        slices: [DonutSlice],
        mode: ChartDisplayMode = .full,
        showAnnotations: Bool = true
    ) {
        self.slices = slices
        self.mode = mode
        self.showAnnotations = showAnnotations
        self.centerContent = { EmptyView() }
    }
}

// MARK: - Previews



