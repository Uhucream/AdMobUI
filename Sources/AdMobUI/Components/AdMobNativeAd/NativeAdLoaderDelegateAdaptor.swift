//
//  NativeAdLoaderDelegateAdaptor.swift
//  AdMob-SwiftUI
//
//  Created by Takashi Ushikoshi on 2026/07/29.
//
//

import GoogleMobileAds

// AdLoader's delegate is an Objective-C protocol, which only an NSObject subclass can satisfy.
// Absorbing that here lets a type receive an AdLoader's callbacks as plain closures, without
// having to inherit from NSObject itself.
@MainActor
internal final class NativeAdLoaderDelegateAdaptor: NSObject {
    private let onReceive: (_ adLoader: AdLoader, _ nativeAd: NativeAd) -> Void
    private let onFailure: (_ adLoader: AdLoader, _ error: any Error) -> Void
    private let onFinishLoading: (_ adLoader: AdLoader) -> Void

    init(
        onReceive: @escaping (_ adLoader: AdLoader, _ nativeAd: NativeAd) -> Void,
        onFailure: @escaping (_ adLoader: AdLoader, _ error: any Error) -> Void,
        onFinishLoading: @escaping (_ adLoader: AdLoader) -> Void
    ) {
        self.onReceive = onReceive
        self.onFailure = onFailure
        self.onFinishLoading = onFinishLoading
        super.init()
    }
}

extension NativeAdLoaderDelegateAdaptor: NativeAdLoaderDelegate {
    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        onReceive(adLoader, nativeAd)
    }

    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: any Error) {
        onFailure(adLoader, error)
    }

    func adLoaderDidFinishLoading(_ adLoader: AdLoader) {
        onFinishLoading(adLoader)
    }
}
