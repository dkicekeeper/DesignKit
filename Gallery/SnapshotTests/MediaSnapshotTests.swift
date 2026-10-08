//
//  MediaSnapshotTests.swift
//  DesignKit Gallery snapshot tests
//
//  Photos, share cards, offline downloads, articles, the live session bar and the profile card
//  (2.8.0, from Dalada). The photos are gradients with a symbol, the same on every run.
//

import SwiftUI
import Testing
import DesignTokens
import DesignSupport
import DesignComponents

/// A stand-in photo: a gradient with a symbol.
private struct SamplePhoto: Identifiable {
    let id: Int
    let colors: [Color]
    let symbol: String

    static let all: [SamplePhoto] = [
        SamplePhoto(id: 0, colors: [.teal, .blue], symbol: "mountain.2.fill"),
        SamplePhoto(id: 1, colors: [.orange, .pink], symbol: "sun.horizon.fill"),
        SamplePhoto(id: 2, colors: [.green, .mint], symbol: "tree.fill"),
        SamplePhoto(id: 3, colors: [.indigo, .purple], symbol: "moon.stars.fill"),
        SamplePhoto(id: 4, colors: [.cyan, .teal], symbol: "fish.fill"),
        SamplePhoto(id: 5, colors: [.yellow, .orange], symbol: "tent.fill"),
    ]

    var view: some View {
        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            .overlay {
                Image(systemName: symbol)
                    .font(.system(size: 28))
                    .foregroundStyle(.white.opacity(0.85))
            }
    }
}

extension ComponentSnapshots {
    @MainActor
    @Suite("Media")
    struct Media {
        @Test func photoTiles() async {
            await assertComponentSnapshot(
                HStack(spacing: AppSpacing.md) {
                    PhotoTile { SamplePhoto.all[0].view }
                    PhotoTile(image: nil)
                    PhotoTile(size: 120) { SamplePhoto.all[1].view }
                }
            )
        }

        /// Photos by address (3.1.0), through the Gallery's DesignKitPhotoLoader (GalleryPhotos):
        /// one the app holds (shown at once), one still loading (its skeleton), one without a URL.
        @Test func remotePhotos() async {
            await assertComponentSnapshot(
                HStack(spacing: AppSpacing.md) {
                    PhotoTile {
                        RemotePhoto(key: "gallery-photo-0", url: URL(string: "https://gallery.invalid/photo/0.jpg"))
                    }
                    PhotoTile {
                        RemotePhoto(key: "gallery-photo-1-pending", url: URL(string: "https://gallery.invalid/photo/1.jpg"))
                    }
                    PhotoTile {
                        RemotePhoto(key: "gallery-photo-2", url: nil)
                    }
                },
                appearances: [.light, .dark]
            )
        }

        @Test func photoStrip() async {
            await assertComponentSnapshot(
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    PhotoStrip(SamplePhoto.all, onOpen: { _ in }) { $0.view }
                    PhotoStrip(Array(SamplePhoto.all.prefix(2)), onRemove: { _ in }) { $0.view }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            )
        }

        @Test func photoGrid() async {
            await assertComponentSnapshot(
                PhotoGrid(SamplePhoto.all, onOpen: { _ in }) { $0.view },
                named: "rounded",
                appearances: [.light]
            )
            await assertComponentSnapshot(
                PhotoGrid(SamplePhoto.all, style: .edgeToEdge, onOpen: { _ in }) { $0.view },
                named: "edgeToEdge",
                appearances: [.light]
            )
        }

        @Test func photoCarousel() async {
            await assertComponentSnapshot(
                PhotoCarousel(Array(SamplePhoto.all.prefix(3)), onOpen: { _ in }) { $0.view },
                appearances: [.light]
            )
        }

        // An image, not a screen: the same in light and dark, so one appearance.
        @Test func shareCardFrame() async {
            for format in ShareCard.Format.allCases {
                await assertComponentSnapshot(
                    ShareCardFrame(format: format, brand: "Dalada", site: "dalada.kz") {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Fishing", systemImage: "fish")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(ShareCard.Style.standard.accent)
                            Text("Kapchagay weekend")
                                .font(.system(size: 30, weight: .bold))
                        }
                        Spacer(minLength: 0)
                        HStack(alignment: .top, spacing: 12) {
                            ShareCardStat(value: "12.4 km", title: "Distance")
                            ShareCardStat(value: "5 h 12 min", title: "Time")
                        }
                    },
                    named: format.rawValue,
                    width: format.width,
                    appearances: [.light]
                )
            }
        }

        @Test func downloadRows() async {
            await assertComponentSnapshot(
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    DownloadRow("Almaty region", status: .available, caption: "About 80 MB", onDownload: {})
                    DownloadRow("Kapchagay", status: .downloading(0.4), caption: "40% · 32 MB", onDownload: {})
                    DownloadRow("Ile-Alatau", status: .paused, caption: "Paused at 60%", onDownload: {})
                    DownloadRow("Charyn", status: .downloaded, caption: "Downloaded · 120 MB", onDownload: {})
                    DownloadRow("Kolsai", status: .failed, caption: "No connection. Try again.", onDownload: {})
                }
                .cardContentPadding()
                .cardStyle(),
                appearances: [.light, .dark, .largeText]
            )
        }

        @Test func articleBody() async {
            await assertComponentSnapshot(
                ArticleBody([
                    .heading("Before you go", level: 2),
                    .paragraph("Check the ice at the shore first: **10 cm** holds a person."),
                    .bullets(["Spare gloves", "Ice picks"]),
                    .heading("On the ice", level: 3),
                    .steps(["Walk in single file", "Turn back at dark patches"]),
                    .note("Fishing is closed from 1 April to 31 May."),
                ]),
                appearances: [.light, .dark, .largeText]
            )
        }

        // No start: the clock reads 0:00:00 on every run.
        @Test func liveSessionBar() async {
            await assertComponentSnapshot(
                VStack(spacing: AppSpacing.lg) {
                    LiveSessionBar(startedAt: nil, detail: "3.2 km", accessibilityLabel: "Recording") {}
                    LiveSessionBar(startedAt: nil, isPaused: true, detail: "3.2 km", accessibilityLabel: "Recording") {}
                }
            )
        }

        @Test func personRowCard() async {
            await assertComponentSnapshot(
                PersonRow(name: "Aida Nurlanovna", subtitle: "@aida", detail: "Almaty", style: .card) {
                    DisclosureChevron()
                },
                appearances: [.light, .dark, .largeText]
            )
        }

        @Test func chipPickerAll() async {
            await assertComponentSnapshot(
                ChipPicker(
                    "Place",
                    options: ["Lake", "River", "Camp"],
                    selection: .constant(Set<String>()),
                    allTitle: "All"
                ) { $0 }
            )
        }
    }
}
