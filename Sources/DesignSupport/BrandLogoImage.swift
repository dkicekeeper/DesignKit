//
//  BrandLogoImage.swift
//  DesignKit
//
//  The brand-logo engine of `Icon(source: .brandService(name))`. The public BrandLogoView
//  (deprecated in 1.13.0) is gone in 2.0.0: `Icon(source: .brandService(name), style:
//  .roundedSquare(size: size))` is its look.
//

import SwiftUI
import DesignTokens

/// Loads a brand logo through the host's `DesignKitLogoLoader` and draws it with a rounded
/// corner, a spinner while it loads and a card symbol when there is none. Used by `Icon`.
/// `.task(id:)` cancels a load when the name changes.
struct BrandLogoImage: View {
    let brandName: String?
    let size: CGFloat

    @State private var logoImage: UIImage?
    @State private var isLoading = false

    var body: some View {
        Group {
            if let logoImage {
                Image(uiImage: logoImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.2))
            } else if isLoading {
                ProgressView()
                    .frame(width: size, height: size)
            } else {
                fallbackIcon
            }
        }
        .task(id: brandName) {
            guard let brandName,
                  !brandName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                logoImage = nil
                isLoading = false
                return
            }

            isLoading = true
            let image = await DesignKitLogoLoader.loader?(brandName)
            logoImage = image
            isLoading = false
        }
    }

    private var fallbackIcon: some View {
        Image(systemName: "creditcard")
            .font(.system(size: size * 0.6))
            .foregroundStyle(.secondary)
            .frame(width: size, height: size)
            .background(AppColors.Background.neutral2)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.2))
    }
}

