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

    private let adUnitId: String
    private let ownSource: OwnSource?
    private var sharedLoader: NativeAdvertisementLoader?

    // Drives its own AdLoader with a caller-supplied request/options, bypassing the shared pool.
    init(
        adUnitId: String,
        request: Request,
        options: [GADAdLoaderOptions]
    ) {
        self.adUnitId = adUnitId

        let adLoader = AdLoader(
            adUnitID: adUnitId,
            rootViewController: nil,
            adTypes: [.native],
            options: options
        )

        self.ownSource = OwnSource(adLoader: adLoader, request: request)

        super.init()

        adLoader.delegate = self
    }

    // Borrows an already-loaded advertisement from a shared NativeAdvertisementLoader, supplied
    // later via loadAd(preferring:) once SwiftUI's environment is available.
    init(adUnitId: String) {
        self.adUnitId = adUnitId
        self.ownSource = nil

        super.init()
    }

    deinit {
        guard let sharedLoader else { return }

        if let nativeAd = nativeAdvertisementPhase.nativeAd {
            sharedLoader.giveBack(nativeAd, forAdUnitId: adUnitId)
        } else {
            sharedLoader.cancelLending(requester: ObjectIdentifier(self), forAdUnitId: adUnitId)
        }
    }
}

extension NativeAdvertisementBinder {
    fileprivate struct OwnSource {
        let adLoader: AdLoader
        let request: Request
    }
}

extension NativeAdvertisementBinder {
    func loadAd(preferring sharedLoader: NativeAdvertisementLoader) {
        if let ownSource {
            ownSource.adLoader.load(ownSource.request)

            return
        }

        guard self.sharedLoader == nil else { return }

        self.sharedLoader = sharedLoader

        sharedLoader.lend(forAdUnitId: adUnitId, requester: ObjectIdentifier(self)) { [weak self] phase in
            self?.nativeAdvertisementPhase = phase
        }
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
