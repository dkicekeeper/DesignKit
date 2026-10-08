//
//  EditSheetContainer.swift
//  Tenra
//
//  Generic wrapper for modal edit-form sheets.
//  Extracts the repeated NavigationView → Form → toolbar(xmark / checkmark) shell
//  that was duplicated across AccountEditView, CategoryEditView, SubcategoryEditView,
//  DepositEditView, and SubscriptionEditView.
//

import SwiftUI
import DesignTokens
import DesignSupport

/// A reusable container that wraps Form content inside a NavigationView
/// with the standard modal edit-sheet chrome: title, cancel (xmark) and save (checkmark) toolbar buttons.
///
/// Usage:
/// ```swift
/// EditSheetContainer(
///     title: account == nil ? "New Account" : "Edit Account",
///     isSaveDisabled: name.isEmpty,
///     onSave: { /* save logic */ },
///     onCancel: onCancel
/// ) {
///     Section(header: Text("Name")) { ... }
///     Section(header: Text("Balance")) { ... }
/// }
/// ```
public struct EditSheetContainer<Content: View>: View {
    /// Navigation title displayed at the top of the sheet
    let title: String
    /// What VoiceOver reads for the checkmark ("Publish", "Send"); Save when `nil` (3.0.0).
    let saveTitle: String?
    /// When `true`, the save (checkmark) button is disabled
    let isSaveDisabled: Bool
    /// When `true`, a spinner stands in for the save button and cancel is disabled while the
    /// save runs (3.0.0).
    let isSaving: Bool
    /// When `true` (default), content is wrapped in `Form {}`.
    /// Pass `false` for hero-style views that supply their own `ScrollView`.
    let wrapInForm: Bool
    /// Called when the user taps the checkmark button
    let onSave: () -> Void
    /// Called when the user taps the xmark button
    let onCancel: () -> Void
    /// The Form sections content provided by the caller
    @ViewBuilder let content: () -> Content

    public init(
        title: String,
        saveTitle: String? = nil,
        isSaveDisabled: Bool,
        isSaving: Bool = false,
        wrapInForm: Bool = true,
        onSave: @escaping () -> Void,
        onCancel: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.saveTitle = saveTitle
        self.isSaveDisabled = isSaveDisabled
        self.isSaving = isSaving
        self.wrapInForm = wrapInForm
        self.onSave = onSave
        self.onCancel = onCancel
        self.content = content
    }

    public var body: some View {
        NavigationStack {
            if wrapInForm {
                Form {
                    content()
                }
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    toolbarContent
                }
            } else {
                content()
                    .navigationTitle(title)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        toolbarContent
                    }
            }
        }
    }
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(action: onCancel) {
                Image(systemName: "xmark")
            }
            .accessibilityLabel(String(localized: "button.cancel"))
            .disabled(isSaving)
        }
        // `.confirmationAction` anchors the Save button to the far-right of the nav bar.
        // Child views can add extra items via `.primaryAction`, which iOS renders
        // to the LEFT of `.confirmationAction` — exactly the visual order we want.
        ToolbarItem(placement: .confirmationAction) {
            if isSaving {
                ProgressView()
                    .accessibilityLabel(saveTitle ?? String(localized: "button.save"))
            } else {
                Button {
                    HapticManager.light()
                    onSave()
                } label: {
                    Image(systemName: "checkmark")
                }
                .disabled(isSaveDisabled)
                .dsButton()
                .accessibilityLabel(saveTitle ?? String(localized: "button.save"))
            }
        }
    }
}

// MARK: - Previews
