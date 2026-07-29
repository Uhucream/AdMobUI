//
//  NativeAdvertisementBinder.swift
//  AdMob-SwiftUI
//
//  Created by Takashi Ushikoshi on 2025/07/09.
//
//

import Combine
import GoogleMobileAds

internal class NativeAdvertisementBinder: NSObject, ObservableObject {
    @Published private(set) var nativeAdvertisementPhase: NativeAdvertisementPhase = .empty

    private let adLoader: AdLoader
    private let request: Request

    init(
        adUnitId: String,
        request: Request,
        options: [GADAdLoaderOptions]
    ) {
        self.request = request

        adLoader = AdLoader(
            adUnitID: adUnitId,
            rootViewController: nil,
            adTypes: [.native],
            options: options
        )

        super.init()

        adLoader.delegate = self
    }
}

extension NativeAdvertisementBinder {
    func loadAd() {
        adLoader.load(request)
    }
}

extension NativeAdvertisementBinder: NativeAdLoaderDelegate {
    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        self.nativeAdvertisementPhase = .success(nativeAd)
    }

    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: any Error) {
        self.nativeAdvertisementPhase = .failure(error)
    }
}
