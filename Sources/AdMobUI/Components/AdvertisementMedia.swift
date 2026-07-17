//
//  AdvertisementMedia.swift
//  AdMob-SwiftUI
//
//  Created by Takashi Ushikoshi on 2025/07/09.
//
//

import GoogleMobileAds
import SwiftUI

public struct AdvertisementMedia: View {
    private let mediaContent: MediaContent

    // nil when the ad has no known aspect ratio (mediaContent.aspectRatio is 0);
    // aspectRatio(_:contentMode:) then leaves the size unconstrained.
    private var resolvedAspectRatio: CGFloat? {
        let aspectRatio: CGFloat = mediaContent.aspectRatio

        guard aspectRatio > 0 else {
            return nil
        }

        return aspectRatio
    }

    public init(mediaContent: MediaContent) {
        self.mediaContent = mediaContent
    }

    public var body: some View {
        Rectangle()
            .fill(.clear)
            .aspectRatio(resolvedAspectRatio, contentMode: .fit)
            .nativeAdElement(.media)
    }
}
