//
//  AdvertisementAdChoices.swift
//  AdMob-SwiftUI
//
//  Created by Takashi Ushikoshi on 2025/07/09.
//
//

import SwiftUI

public struct AdvertisementAdChoices: View {
    public init() {}

    public var body: some View {
        // A transparent placeholder that only marks the AdChoices slot. The AdChoices
        // icon itself is rendered by the AdChoicesView that _RepresentedUINativeAdView
        // registers as the overlay ad view's adChoicesView.
        Rectangle()
            .fill(.clear)
            .nativeAdElement(.adChoices)
    }
}
