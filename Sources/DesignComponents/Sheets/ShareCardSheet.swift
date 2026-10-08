//
//  ShareCardSheet.swift
//  DesignKit
//
//  The sheet that turns something into a picture to share (2.8.0): pick Stories or post, see the
//  picture, send it with the system share sheet. The data loads when the sheet opens; the picture
//  is drawn on the phone (`ImageRenderer`, 1080 px wide). Ported from Dalada's ShareCardSheet; the
//  card (usually a `ShareCardFrame`) and the message are the app's.
//
//  While the data loads, the preview is the card's skeleton (Dalada showed a spinner).
//

import SwiftUI
import UIKit
import DesignTokens
import DesignSupport

/// Picks a format, previews the picture and shares it.
///
/// ```swift
/// .sheet(isPresented: $sharing) {
///     ShareCardSheet(previewTitle: "Dalada") {
///         try? await backend.tripShareCard(tripID)
///     } message: { card in
///         "\(card.title) \(link)"
///     } card: { card, format in
///         TripShareCardView(card: card, format: format)
///     }
/// }
/// ```
public struct ShareCardSheet<Model, Card: View>: View {
    let title: String
    let previewTitle: String
    let formats: [ShareCardFormat]
    let load: @MainActor () async -> Model?
    let message: @MainActor (Model) -> String
    let card: @MainActor (Model, ShareCardFormat) -> Card

    @Environment(\.dismiss) private var dismiss
    @State private var model: Model?
    @State private var isLoaded = false
    @State private var format: ShareCardFormat
    @State private var image: UIImage?

    /// - Parameters:
    ///   - title: The sheet's title.
    ///   - previewTitle: What the system share sheet calls the picture (the app's name).
    ///   - formats: The formats to offer; the first is shown first. One format hides the picker.
    ///   - load: The card's data; `nil` shows the error state.
    ///   - message: The text sent with the picture (a link).
    ///   - card: The card for the data in a format, at the format's size.
    public init(
        title: String = String(localized: "share.title", defaultValue: "Picture for Stories"),
        previewTitle: String,
        formats: [ShareCardFormat] = ShareCardFormat.allCases,
        load: @escaping @MainActor () async -> Model?,
        message: @escaping @MainActor (Model) -> String,
        @ViewBuilder card: @escaping @MainActor (Model, ShareCardFormat) -> Card
    ) {
        let offered = formats.isEmpty ? ShareCardFormat.allCases : formats
        self.title = title
        self.previewTitle = previewTitle
        self.formats = offered
        self.load = load
        self.message = message
        self.card = card
        self._format = State(initialValue: offered[0])
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.lg) {
                if formats.count > 1 {
                    Picker(String(localized: "share.format", defaultValue: "Format"), selection: $format) {
                        ForEach(formats) { format in
                            Text(verbatim: format.title).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                preview
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                if let image, let model {
                    ShareLink(
                        item: Image(uiImage: image),
                        message: Text(verbatim: message(model)),
                        preview: SharePreview(Text(verbatim: previewTitle), image: Image(uiImage: image))
                    ) {
                        Label(String(localized: "share.send", defaultValue: "Share"), systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .dsButton()
                }
            }
            .screenPadding()
            .padding(.vertical, AppSpacing.lg)
            .navigationTitle(Text(verbatim: title))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.close", defaultValue: "Close"), systemImage: "xmark") { dismiss() }
                }
            }
            .task {
                model = await load()
                isLoaded = true
                render()
            }
            .onChange(of: format) { _, _ in render() }
        }
    }

    @ViewBuilder
    private var preview: some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                .shadow(color: .black.opacity(0.25), radius: 12, y: 4)
                .accessibilityLabel(Text(verbatim: title))
        } else if isLoaded {
            EmptyState(
                icon: "photo",
                title: String(localized: "share.failed", defaultValue: "Couldn’t prepare the picture"),
                style: .error
            )
        } else {
            ShareCardSkeleton(format: format)
        }
    }

    private func render() {
        guard let model else { return }
        let renderer = ImageRenderer(
            content: card(model, format)
                .frame(width: format.width, height: format.height)
                .environment(\.colorScheme, .dark)
        )
        renderer.scale = ShareCardFormat.scale
        image = renderer.uiImage
    }
}
