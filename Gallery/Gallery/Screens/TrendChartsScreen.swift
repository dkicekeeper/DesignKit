//
//  TrendChartsScreen.swift
//  DesignKit Gallery
//
//  The ChartPoint chart family (0.5.0): ChartSwitcher (LineChart / BarChart), signed
//  series, HeroSparkline, Sparkline and the selection banner, on demo data.
//

import SwiftUI
import DesignTokens
import DesignSupport
import DesignComponents

struct TrendChartsScreen: View {
    private let months = TrendChartsScreen.demoMonths()

    private let income = ChartSeries<ChartValuePoint>.keyed(
        "income", name: "Income", coloring: .solid(AppColors.success))
    private let expenses = ChartSeries<ChartValuePoint>.keyed(
        "expenses", name: "Expenses", coloring: .solid(AppColors.destructive))
    private let netFlow = ChartSeries<ChartValuePoint>(
        id: "net", name: "Net", coloring: .signed(positive: AppColors.success, negative: AppColors.destructive),
        baseline: .signed
    ) { $0["income"] - $0["expenses"] }
    private let distance = ChartSeries<ChartValuePoint>.keyed(
        "km", name: "Distance", coloring: .solid(AppColors.accent))

    var body: some View {
        ShowcasePage(title: "Trend Charts") {
            switcherSection
            signedSection
            heroSection
            sparklineSection
            bannerSection
        }
    }

    private var switcherSection: some View {
        ShowcaseSection(title: "ChartSwitcher", subtitle: "LineChart ⇄ BarChart · zoom · tap a point · two series") {
            ChartSwitcher(
                dataPoints: months,
                series: [income, expenses],
                valueFormat: .currency("KZT"),
                todayText: "Today"
            )
            .padding(.horizontal, -AppSpacing.lg)
        }
    }

    private var signedSection: some View {
        ShowcaseSection(title: "LineChart · signed series", subtitle: "Green above zero, red below, dashed zero rule") {
            LineChart(dataPoints: months, series: netFlow, valueFormat: .currency("KZT"), todayText: "Today")
                .padding(.horizontal, -AppSpacing.lg)
        }
    }

    private var heroSection: some View {
        ShowcaseSection(title: "HeroSparkline", subtitle: "Projection tail · min/max markers · tap") {
            HeroSparkline(
                dataPoints: Array(months.suffix(8)),
                series: distance,
                projectedValue: 64,
                markExtremes: true,
                valueFormat: .custom({ "\($0.formatted(.number.precision(.fractionLength(0...1)))) km" })
            )
            .padding(.horizontal, -AppSpacing.lg)
        }
    }

    private var sparklineSection: some View {
        ShowcaseSection(title: "Sparkline", subtitle: "Canvas · cards and feeds") {
            HStack(spacing: AppSpacing.lg) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    TokenLabel(name: "solid")
                    Sparkline(dataPoints: months, series: distance)
                }
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    TokenLabel(name: "signed")
                    Sparkline(dataPoints: months, series: netFlow)
                }
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    TokenLabel(name: "forecast")
                    Sparkline(values: [12, 18, 15, 22, 27], coloring: .solid(AppColors.warning), projectedValue: 34)
                }
            }
            .frame(height: 60)
        }
    }

    private var bannerSection: some View {
        ShowcaseSection(title: "ChartSelectionBanner", subtitle: "Title + one or more values") {
            ChartSelectionBanner(title: "январь 2026", entries: [
                .init(value: 480_000, color: AppColors.success),
                .init(value: 275_000, color: AppColors.destructive),
            ], format: .currency("KZT"))
            ChartSelectionBanner(title: "Week 12", entries: [
                .init(value: 42.5, color: AppColors.accent, showsDot: false),
            ], format: .custom({ "\($0.formatted()) km" }))
        }
    }

    // MARK: Demo data

    private static func demoMonths() -> [ChartValuePoint] {
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .month, value: -14, to: calendar.startOfDay(for: .now)) ?? .now
        let axis = DateFormatter()
        axis.dateFormat = "MMM"
        let title = DateFormatter()
        title.dateFormat = "LLLL yyyy"
        let incomes: [Double] = [420, 455, 430, 510, 480, 495, 520, 470, 530, 560, 540, 575, 590, 610, 600, 620]
        let spending: [Double] = [380, 410, 470, 450, 520, 430, 480, 500, 460, 590, 510, 540, 560, 580, 520, 610]
        let km: [Double] = [18, 25, 31, 22, 40, 52, 47, 38, 55, 61, 44, 58, 49, 66, 57, 60]
        return (0..<16).map { i in
            let date = calendar.date(byAdding: .month, value: i, to: start) ?? start
            return ChartValuePoint(
                label: "m\(i)",
                axisLabel: axis.string(from: date).uppercased(),
                title: title.string(from: date),
                date: date,
                values: ["income": incomes[i] * 1_000, "expenses": spending[i] * 1_000, "km": km[i]]
            )
        }
    }
}

#Preview { NavigationStack { TrendChartsScreen() } }
