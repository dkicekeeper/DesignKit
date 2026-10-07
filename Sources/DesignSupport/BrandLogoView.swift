//
//  BrandLogoView.swift
//  Tenra
//
//  SwiftUI component for displaying brand logos via provider chain
//

import SwiftUI
import DesignTokens

/// A brand logo by name. Deprecated as a public view since 1.13.0: it is the engine of
/// `IconView(source: .brandService(name))`, which adds the icon style (shape, size, glass) and
/// the skeleton; call that instead. `style: .roundedSquare(size: size)` keeps this view's look
/// (a corner of 20% of the size).
@available(*, deprecated, message: "Use IconView(source: .brandService(name), style: .roundedSquare(size: size)): the same look, with the icon style and skeleton.")
public struct BrandLogoView: View {
    let brandName: String?
    let size: CGFloat

    public init(brandName: String?, size: CGFloat = AppIconSize.xl) {
        self.brandName = brandName
        self.size = size
    }

    public var body: some View {
        BrandLogoImage(brandName: brandName, size: size)
    }
}

/// Loads a brand logo through the host's `DesignKitLogoLoader` and draws it with a rounded
/// corner, a spinner while it loads and a card symbol when there is none. Used by `IconView`.
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

