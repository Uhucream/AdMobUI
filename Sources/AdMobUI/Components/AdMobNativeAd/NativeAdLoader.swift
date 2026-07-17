//
//  NativeAdLoader.swift
//  AdMob-SwiftUI
//  
//  Created by Takashi Ushikoshi on 2025/07/09.
//  
//

import Combine
import GoogleMobileAds

internal class NativeAdLoader: NSObject, ObservableObject {
    @Published private(set) var nativeAdvertisementPhase: NativeAdvertisementPhase = .empty

    private let adLoader: AdLoader

    init(adUnitId: String) {
        adLoader = AdLoader(
            adUnitID: adUnitId,
            rootViewController: nil,
            adTypes: [.native],
            options: [GADAdLoaderOptions()]
        )

        super.init()

        adLoader.delegate = self
    }
}

extension NativeAdLoader {
    func loadAd() {
        adLoader.load(Request())
    }
}

extension NativeAdLoader: NativeAdLoaderDelegate {
    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        self.nativeAdvertisementPhase = .success(nativeAd)
    }

    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: any Error) {
        self.nativeAdvertisementPhase = .failure(error)
    }
}
