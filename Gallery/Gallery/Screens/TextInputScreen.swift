//
//  TextInputScreen.swift
//  DesignKit Gallery
//
//  Text input: fields, the hero title, the message field, tags.
//

import SwiftUI
import DesignTokens
import DesignSupport
import DesignComponents

struct TextInputScreen: View {
    var body: some View {
        ShowcasePage(title: "Text Input") {
            FormTextFieldPage()
            AnimatedTitleInputPage()
            MessageComposerPage()
            TagInputPage()
        }
    }
}

private struct FormTextFieldPage: View {
    @State private var text = "Big Almaty Lake"
    @State private var style = 0
    @State private var showsError = false
    @State private var showsHelp = true
    @State private var disabled = false

    private var fieldStyle: FormTextField.Style {
        switch style {
        case 1: return .multiline(min: 2, max: 5)
        case 2: return .inline
        default: return .standard
        }
    }

    var body: some View {
        ComponentPage(
            name: "FormTextField",
            summary: "A form field with focus, error, help and disabled states; inline styles sit in a row's trailing slot.",
            apps: [.tenra, .dalada],
            canvas: .fill,
            notes: ["Inline styles show no error or help text: put validation at the form level (InlineStatusText)."]
        ) {
            if style == 2 {
                UniversalRow(config: .standard) {
                    Text("Name").font(AppTypography.body)
                } trailing: {
                    FormTextField(text: $text, placeholder: "Place name", style: fieldStyle, isDisabled: disabled)
                }
            } else {
                FormTextField(
                    text: $text,
                    placeholder: "Place name",
                    style: fieldStyle,
                    errorMessage: showsError ? "The name is too short" : nil,
                    helpText: showsHelp ? "Shown on the map" : nil,
                    isDisabled: disabled
                )
            }
        } controls: {
            ChoiceControl("Style", selection: $style, options: [("Standard", 0), ("Multiline", 1), ("Inline", 2)])
            ToggleControl("Error", isOn: $showsError)
            ToggleControl("Help text", isOn: $showsHelp)
            ToggleControl("Disabled", isOn: $disabled)
            TextControl("Text", text: $text)
        }
    }
}

private struct AnimatedTitleInputPage: View {
    @State private var title = ""
    @State private var alignment = 0

    var body: some View {
        ComponentPage(
            name: "AnimatedTitleInput",
            summary: "A large title typed in place, each letter animating in: the name in an edit sheet's hero.",
            apps: [.tenra]
        ) {
            AnimatedTitleInput(text: $title, placeholder: "Untitled",
                               alignment: alignment == 0 ? .center : .leading)
        } controls: {
            ChoiceControl("Alignment", selection: $alignment, options: [("Center", 0), ("Leading", 1)])
            TextControl("Text", text: $title)
        }
    }
}

private struct MessageComposerPage: View {
    @State private var text = ""
    @State private var showsQuote = true
    @State private var showsError = false
    @State private var isSending = false
    @State private var disabled = false

    var body: some View {
        ComponentPage(
            name: "MessageComposer",
            summary: "The field at the bottom of a conversation: glass that grows to five lines, the send button inside, the quoted message, the send error.",
            since: "1.12.0",
            apps: [.dalada],
            canvas: .fill,
            notes: [
                "Put it in safeAreaBar(edge: .bottom) so the list scrolls under the glass; give it the screen margins.",
                "Signed out: .disabled(true) with a placeholder that says why.",
            ]
        ) {
            MessageComposer(
                text: $text,
                placeholder: disabled ? "Sign in to comment" : "Add a comment…",
                quote: showsQuote ? MessageQuote(title: "Replying to Aida", text: "Was anyone on the lake this weekend?") : nil,
                isSending: isSending,
                errorMessage: showsError ? "No connection. Try again." : nil,
                onCancelQuote: { showsQuote = false }
            ) {
                isSending = true
                Task {
                    try? await Task.sleep(for: .seconds(1))
                    text = ""
                    isSending = false
                }
            }
            .disabled(disabled)
        } controls: {
            ToggleControl("Quote", isOn: $showsQuote)
            ToggleControl("Error", isOn: $showsError)
            ToggleControl("Sending", isOn: $isSending)
            ToggleControl("Disabled", isOn: $disabled)
        }
    }
}

private struct TagInputPage: View {
    @State private var tags = ["Pike", "Early morning"]
    @State private var limited = false

    var body: some View {
        ComponentPage(
            name: "TagInput",
            summary: "Free-form tags as removable chips, a field for the next one and matching suggestions.",
            since: "0.7.0",
            apps: [.dalada],
            canvas: .fill,
            notes: ["Return or a comma adds a tag; duplicates and blanks are dropped. A fixed set of options → ChipPicker."]
        ) {
            TagInput("Add a tag", tags: $tags, suggestions: ["Perch", "Night", "Kids", "4x4 only"],
                     maxTags: limited ? 3 : nil)
        } controls: {
            ToggleControl("At most 3", isOn: $limited)
            ActionControl("Clear", systemImage: "xmark.circle") { tags = [] }
        }
    }
}

#Preview { NavigationStack { TextInputScreen() } }
