//
//  RootView.swift
//  DesignKit Gallery
//

import SwiftUI
import DesignTokens

struct RootView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Foundations") {
                    row("Colors", "paintpalette.fill", AppColors.accent) { ColorsScreen() }
                    row("Typography", "textformat", .pink) { TypographyScreen() }
                    row("Spacing & Radius", "ruler.fill", .orange) { SpacingScreen() }
                    row("Icon Sizes", "square.resize", .teal) { IconSizesScreen() }
                }
                Section("Elements") {
                    row("Icons", "star.circle.fill", .indigo) { IconsScreen() }
                    row("Buttons", "hand.tap.fill", .blue) { ButtonsScreen() }
                    row("Cards & Surfaces", "rectangle.on.rectangle", .green) { CardsScreen() }
                    row("Motion", "wand.and.rays", .purple) { MotionScreen() }
                }
                Section("Components") {
                    row("Components", "square.grid.2x2.fill", AppColors.accent) { ComponentsScreen() }
                }
            }
            .navigationTitle("DesignKit")
        }
    }

    private func row<Destination: View>(
        _ title: String,
        _ symbol: String,
        _ tint: Color,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        NavigationLink {
            destination()
        } label: {
            Label {
                Text(title).font(AppTypography.bodyEmphasis)
            } icon: {
                Image(systemName: symbol)
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(tint, in: RoundedRectangle(cornerRadius: 7))
            }
        }
    }
}

#Preview { RootView() }
