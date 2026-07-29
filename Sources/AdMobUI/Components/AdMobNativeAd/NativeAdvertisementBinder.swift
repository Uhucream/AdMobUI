//
//  NativeAdvertisementBinder.swift
//  AdMob-SwiftUI
//
//  Created by Takashi Ushikoshi on 2025/07/09.
//
//

import Combine
import GoogleMobileAds

@MainActor
internal class NativeAdvertisementBinder: ObservableObject {
    @Published private(set) var nativeAdvertisementPhase: NativeAdvertisementPhase = .empty {
        didSet {
            currentNativeAd = nativeAdvertisementPhase.nativeAd
        }
    }

    private let adUnitId: String
    private var advertisementLoader: NativeAdvertisementLoader?

    // deinit is nonisolated even on a @MainActor class, and @Published's synthesized accessor
    // can't be read from there (a plain stored property can). This mirrors just the part deinit
    // needs to decide between giving an advertisement back and cancelling a pending request.
    private var currentNativeAd: NativeAd?

    init(adUnitId: String) {
        self.adUnitId = adUnitId
    }

    deinit {
        guard let advertisementLoader else { return }

        // deinit is nonisolated even on a @MainActor class, so the loader's @MainActor methods
        // can't be called directly. self is being torn down and must not be captured, so the
        // values the hop needs are read out first.
        let capturedAdUnitId: String = adUnitId
        let capturedNativeAd: NativeAd? = currentNativeAd
        let requester: ObjectIdentifier = ObjectIdentifier(self)

        Task { @MainActor in
            if let capturedNativeAd {
                advertisementLoader.giveBack(capturedNativeAd, for: capturedAdUnitId)
            } else {
                advertisementLoader.cancelLending(requester: requester, for: capturedAdUnitId)
            }
        }
    }
}

extension NativeAdvertisementBinder {
    func loadAd(with loader: NativeAdvertisementLoader) {
        // Asking again once a loader is bound would duplicate a billed request.
        guard advertisementLoader == nil else { return }

        advertisementLoader = loader

        loader.lend(for: adUnitId, requester: ObjectIdentifier(self)) { [weak self] phase in
            self?.nativeAdvertisementPhase = phase
        }
    }
}
