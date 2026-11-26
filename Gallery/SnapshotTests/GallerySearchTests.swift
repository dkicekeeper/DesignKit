//
//  GallerySearchTests.swift
//  DesignKit Gallery snapshot tests
//
//  vNext: the home screen's search over the component pages. The index is the one the release
//  notes link through (`ComponentIndex`), with each page's summary.
//

import Testing
@testable import DesignKitGallery

@MainActor
@Suite("Gallery search")
struct GallerySearchTests {
    private var index: ComponentIndex {
        var index = ComponentIndex()
        index.register(page: "AvatarGroup", summary: "Overlapping avatars and \"+N\".", on: .media)
        index.register(page: "Avatar", summary: "A person's photo or initials.", on: .media)
        index.register(page: "Rating · RatingPicker", summary: "Stars to read and to pick.", on: .selection)
        index.register(page: "LoadMoreFooter", summary: "The end of a list that loads in pages.", on: .feedback)
        index.register(page: ".dsRefreshable · RefreshIndicator", summary: "Pull to refresh with mercury.", on: .feedback)
        return index
    }

    @Test("A part of a name finds its page, names before summaries")
    func byName() {
        #expect(index.search("avatarg").first?.page == "AvatarGroup")
        #expect(index.search("Avatar").map(\.page).prefix(2) == ["Avatar", "AvatarGroup"])
    }

    @Test("Either name of a two-component page finds it")
    func eitherName() {
        #expect(index.search("RatingPicker").first?.page == "Rating · RatingPicker")
        #expect(index.search("refreshindicator").first?.page == ".dsRefreshable · RefreshIndicator")
    }

    @Test("A skeleton and a 1.x name with View find the component")
    func skeletonAndOldName() {
        #expect(index.search("AvatarGroupSkeleton").first?.page == "AvatarGroup")
        #expect(index.search("AvatarView").first?.page == "Avatar")
    }

    @Test("A word of a summary finds its page")
    func bySummary() {
        #expect(index.search("mercury").map(\.page) == [".dsRefreshable · RefreshIndicator"])
        #expect(index.search("pages").map(\.page) == ["LoadMoreFooter"])
    }

    @Test("Nothing matches: no results")
    func noMatch() {
        #expect(index.search("zzzz").isEmpty)
        #expect(index.search("   ").isEmpty)
    }

    @Test("Foundations are found by their titles")
    func foundations() {
        #expect(GalleryFoundation.matching("typo") == [.typography])
        #expect(GalleryFoundation.matching("COLOR") == [.colors])
        #expect(GalleryFoundation.matching("zzzz").isEmpty)
    }
}
