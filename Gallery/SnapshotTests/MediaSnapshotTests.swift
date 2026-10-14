//
//  MediaSnapshotTests.swift
//  DesignKit Gallery snapshot tests
//
//  Photos, share cards, offline downloads, articles, the live session bar and the profile card
//  (2.8.0, from Dalada). The photos are gradients with a symbol, the same on every run.
//  The particle creature (4.6.0) in its still frames: the harness turns motion off, so each mood
//  is drawn settled, with the eyes open and looking ahead.
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
                        RemotePhoto(key: "gallery-photo-2-missing", url: nil)
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

        /// 4.6.0: the creature's still frames, every mood, on the page: all light in dark mode,
        /// all ink in light mode (4.6.1); without its glass since 4.7.0, a glow and a rim of
        /// light round the swarm, a soft shadow under it.
        @Test func particleCreature() async {
            let moods: [ParticleCreature.Mood] = [
                .idle, .listening, .thinking,
                .answering, .glyph("₸"), .happy,
                .celebrating, .surprised, .love,
                .proud, .wink, .confused,
                .determined, .worried, .sad,
                .sleepy, .asleep,
            ]
            await assertComponentSnapshot(
                VStack(spacing: AppSpacing.md) {
                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(100), spacing: AppSpacing.md), count: 3), spacing: AppSpacing.md) {
                        ForEach(moods.indices, id: \.self) { index in
                            ParticleCreature(mood: moods[index]).frame(width: 100, height: 100)
                        }
                    }
                    HStack(spacing: AppSpacing.lg) {
                        ParticleCreature(mood: .idle, style: .compact).frame(width: 40, height: 40)
                        ParticleCreature(mood: .happy, style: .compact).frame(width: 40, height: 40)
                        ParticleCreature(mood: .love, style: .compact).frame(width: 40, height: 40)
                        ParticleCreature(mood: .thinking, style: .compact).frame(width: 28, height: 28)
                    }
                }
                .padding(AppSpacing.lg),
                appearances: [.light, .dark]
            )
        }

        /// 4.10.0: words of light, every letter in place (motion is off): joy over a happy
        /// creature (the emotion from its mood) and a calm line beside an idle one.
        /// `.untilChanged`, so the words cannot leave while they are captured.
        @Test func particleCreatureSpeech() async {
            await assertComponentSnapshot(
                VStack(spacing: AppSpacing.lg) {
                    ParticleCreature(
                        mood: .happy,
                        speech: CreatureSpeech("Hi! Three payments this week.", duration: .untilChanged)
                    )
                    .frame(width: 140, height: 140)
                    .padding(.top, 110)
                    .frame(maxWidth: .infinity)
                    ParticleCreature(
                        mood: .idle,
                        speech: CreatureSpeech("Ask me anything", placement: .trailing, duration: .untilChanged)
                    )
                    .frame(width: 110, height: 110)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(AppSpacing.lg),
                appearances: [.light, .dark, .largeText]
            )
        }

        /// 4.10.0: a thought over the creature, slanted, and a whisper beside a sleepy one.
        @Test func particleCreatureThought() async {
            await assertComponentSnapshot(
                VStack(spacing: AppSpacing.lg) {
                    ParticleCreature(
                        mood: .idle,
                        speech: CreatureSpeech("Coffee again?", emotion: .thought, duration: .untilChanged)
                    )
                    .frame(width: 140, height: 140)
                    .padding(.top, 90)
                    .frame(maxWidth: .infinity)
                    ParticleCreature(
                        mood: .sleepy,
                        speech: CreatureSpeech("Psst… it's late", placement: .trailing, duration: .untilChanged)
                    )
                    .frame(width: 110, height: 110)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(AppSpacing.lg),
                appearances: [.light, .dark, .largeText]
            )
        }

        /// 4.10.0: the other emotions beside the creature: worried letters out of line, dizzy
        /// ones tilted, sad ones sunk and paler.
        @Test func particleCreatureFeelings() async {
            await assertComponentSnapshot(
                VStack(spacing: AppSpacing.lg) {
                    ParticleCreature(
                        mood: .worried,
                        speech: CreatureSpeech("No connection…", placement: .trailing, duration: .untilChanged)
                    )
                    .frame(width: 100, height: 100)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    ParticleCreature(
                        mood: .idle,
                        speech: CreatureSpeech("Whoa, I'm dizzy!", emotion: .dizzy, placement: .trailing, duration: .untilChanged)
                    )
                    .frame(width: 100, height: 100)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    ParticleCreature(
                        mood: .sad,
                        speech: CreatureSpeech("Not this time", placement: .trailing, duration: .untilChanged)
                    )
                    .frame(width: 100, height: 100)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(AppSpacing.lg),
                appearances: [.light, .dark]
            )
        }

        /// 4.10.0: gestures held halfway in a still frame: the hand of particles waving and
        /// pointing each way, a nod, a hop in the air, a shrug, a perk.
        @Test func particleCreatureGestures() async {
            let frames: [(CreatureGesture, Double)] = [
                (.wave, 0.5), (.point(.trailing), 0.5), (.point(.up), 0.5),
                (.nod, 0.25), (.hop, 0.45), (.shrug, 0.5),
            ]
            await assertComponentSnapshot(
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(100), spacing: AppSpacing.md), count: 3), spacing: AppSpacing.md) {
                    ForEach(frames.indices, id: \.self) { index in
                        ParticleCreature(mood: .happy)
                            .creatureGestureFrame(frames[index].0, progress: frames[index].1)
                            .frame(width: 100, height: 100)
                    }
                }
                .padding(AppSpacing.lg),
                appearances: [.light, .dark]
            )
        }

        /// 4.8.0: the still glyph at a tab icon's size and larger, and the tab label it makes.
        @Test func creatureGlyph() async {
            await assertComponentSnapshot(
                HStack(spacing: AppSpacing.lg) {
                    CreatureGlyph().fill(AppColors.accent).frame(width: 22, height: 22)
                    CreatureGlyph().fill(AppColors.Text.primary).frame(width: 44, height: 44)
                    CreatureGlyph().fill(AppColors.accent).frame(width: 88, height: 88)
                    CreatureTabLabel(title: "Assistant")
                        .foregroundStyle(AppColors.accent)
                }
                .padding(AppSpacing.lg),
                appearances: [.light, .dark]
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
