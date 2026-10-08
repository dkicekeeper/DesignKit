//
//  ShareCardFormatTests.swift
//  DesignKit
//
//  The share card's formats render at the sizes Stories and posts expect (2.8.0, moved here from
//  Dalada's DaladaCore with the format).
//

import Testing
@testable import DesignComponents

@Suite("Share card formats")
struct ShareCardFormatTests {
    @Test("Stories is 1080 × 1920, a post 1080 × 1350")
    func pixelSizes() {
        #expect(ShareCard.Format.story.width * ShareCard.Format.scale == 1080)
        #expect(ShareCard.Format.story.height * ShareCard.Format.scale == 1920)
        #expect(ShareCard.Format.post.height * ShareCard.Format.scale == 1350)
    }
}
