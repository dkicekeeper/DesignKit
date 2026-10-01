//
//  AvatarView.swift
//  DesignKit
//
//  Round avatar: a photo when there is one, otherwise the name's initials on a tint.
//  From Dalada's PersonAvatar (friends, profiles, trip owners).
//

import SwiftUI
import DesignTokens
import DesignSupport

/// Round person avatar.
///
/// ```swift
/// AvatarView(name: "Ayan Seitkali")                 // "AS" on a 15 % accent tint
/// AvatarView(name: profile.displayName ?? profile.username, size: 64)
/// AvatarView(name: "Ayan", image: Image(uiImage: photo))
/// ```
///
/// Initials are the first letters of the first two words, upper-cased; an empty name shows "?".
/// The avatar is decorative for VoiceOver: the row next to it carries the name.
public struct AvatarView: View {
    let name: String?
    let image: Image?
    let size: CGFloat
    let tint: Color

    public init(
        name: String?,
        image: Image? = nil,
        size: CGFloat = AppIconSize.avatar,
        tint: Color = AppColors.accent
    ) {
        self.name = name
        self.image = image
        self.size = size
        self.tint = tint
    }

    public var body: some View {
        Group {
            if let image {
                image
                    .resizable()
                    .scaledToFill()
            } else {
                Circle()
                    .fill(tint.opacity(0.15))
                    .overlay {
                        Text(verbatim: Self.initials(from: name))
                            .font(size > 48 ? AppTypography.h3 : AppTypography.bodyEmphasis)
                            .foregroundStyle(tint)
                    }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityHidden(true)
    }

    /// "Ayan Seitkali" → "AS", "ayan" → "A", nil / "" → "?".
    public static func initials(from name: String?) -> String {
        let words = (name ?? "").split(separator: " ").prefix(2)
        let letters = words.compactMap(\.first).map(String.init).joined().uppercased()
        return letters.isEmpty ? "?" : letters
    }
}
