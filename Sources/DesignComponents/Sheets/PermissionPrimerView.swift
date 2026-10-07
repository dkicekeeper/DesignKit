//
//  PermissionPrimerView.swift
//  DesignKit
//
//  The permission primer of 0.7.0–1.x. Since 2.0.0 PromptSheet is the one sheet of its kind;
//  this wrapper keeps the primer's behaviour (no self-dismiss, no detent) for old callers.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// The permission primer: since 2.0.0 a `PromptSheet` that does not close itself or set its
/// detent, as the primer did.
@available(*, deprecated, message: "Use PromptSheet(systemImage:title:message:primaryTitle:secondaryTitle:detent: nil, dismissesOnAnswer: false, onPrimary:onSecondary:).")
public struct PermissionPrimerView: View {
    let systemImage: String
    let title: String
    let message: String
    let allowTitle: String
    let laterTitle: String
    let onAllow: () async -> Void
    let onLater: () -> Void

    public init(
        systemImage: String,
        title: String,
        message: String,
        allowTitle: String,
        laterTitle: String,
        onAllow: @escaping () async -> Void,
        onLater: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.title = title
        self.message = message
        self.allowTitle = allowTitle
        self.laterTitle = laterTitle
        self.onAllow = onAllow
        self.onLater = onLater
    }

    public var body: some View {
        PromptSheet(
            systemImage: systemImage,
            title: title,
            message: message,
            primaryTitle: allowTitle,
            secondaryTitle: laterTitle,
            detent: nil,
            dismissesOnAnswer: false,
            onPrimary: onAllow,
            onSecondary: onLater
        )
    }
}
