//
//  NativeAdvertisement.swift
//  AdMob-SwiftUI
//
//  Created by Takashi Ushikoshi on 2025/07/09.
//
//

import GoogleMobileAds
import SwiftUI

public struct NativeAdvertisement<AdContent: View>: View {
    @StateObject private var nativeAdLoader: NativeAdLoader

    private let adUnitId: String

    @ViewBuilder private let adContent: (_ advertisementPhase: NativeAdvertisementPhase) -> AdContent

    public init(
        adUnitId: String,
        @ViewBuilder adContent: @escaping (_ advertisementPhase: NativeAdvertisementPhase) -> AdContent
    ) {
        self.adContent = adContent
        self.adUnitId = adUnitId

        _nativeAdLoader = StateObject(
            wrappedValue: NativeAdLoader(
                adUnitId: adUnitId
            )
        )
    }

    public var body: some View {
        let loadedAd = nativeAdLoader.nativeAdvertisementPhase.nativeAd

        adContent(nativeAdLoader.nativeAdvertisementPhase)
            .overlayPreferenceValue(TypedAnchorBoundsPreferenceKey.self, alignment: .center) { namedAnchors in
                GeometryReader { overlayGeometry in
                    let elementFrames: [ElementFrame] = namedAnchors.map {
                        .init(
                            elementType: $0.viewType,
                            frame: overlayGeometry[$0.anchor]
                        )
                    }

                    _RepresentedUINativeAdView(
                        nativeAd: loadedAd,
                        elementFrames: elementFrames
                    )
                    .equatable()
                    .frame(width: overlayGeometry.size.width, height: overlayGeometry.size.height)
                }
            }
            .onAppear {
                nativeAdLoader.loadAd()
            }
    }
}
