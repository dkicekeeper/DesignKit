//
//  BrandLogoView.swift
//  Tenra
//
//  SwiftUI component for displaying brand logos via provider chain
//

import SwiftUI
import DesignTokens

/// Displays a brand logo loaded through the LogoService provider chain.
/// No longer uses AsyncImage — relies entirely on the chain result.
/// Uses .task(id:) for automatic cancellation on brandName change.
public struct BrandLogoView: View {
    let brandName: String?
    let size: CGFloat

    @State private var logoImage: UIImage?
    @State private var isLoading = false

    public init(brandName: String?, size: CGFloat = 32) {
        self.brandName = brandName
        self.size = size
    }

    public var body: some View {
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
            .background(AppColors.bgMuted)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.2))
    }
}

