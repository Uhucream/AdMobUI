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
internal class NativeAdvertisementBinder: NSObject, ObservableObject {
    @Published private(set) var nativeAdvertisementPhase: NativeAdvertisementPhase = .empty

    private let adUnitId: String
    private let source: Source?
    private var advertisementLoader: NativeAdvertisementLoader?
    private var hasStartedOwnLoad: Bool = false

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

        self.source = Source(adLoader: adLoader, request: request)

        super.init()

        adLoader.delegate = self
    }

    // Borrows an already-loaded advertisement from a shared NativeAdvertisementLoader, supplied
    // later via loadAd(with:) once SwiftUI's environment is available.
    init(adUnitId: String) {
        self.adUnitId = adUnitId
        self.source = nil

        super.init()
    }

    deinit {
        guard let advertisementLoader else { return }

        if let nativeAd = nativeAdvertisementPhase.nativeAd {
            advertisementLoader.giveBack(nativeAd, for: adUnitId)
        } else {
            advertisementLoader.cancelLending(requester: ObjectIdentifier(self), for: adUnitId)
        }
    }
}

extension NativeAdvertisementBinder {
    fileprivate struct Source {
        let adLoader: AdLoader
        let request: Request
    }
}

extension NativeAdvertisementBinder {
    func loadAd(with loader: NativeAdvertisementLoader) {
        if let source {
            // Without this guard, every onAppear (e.g. a NavigationStack pop or TabView switch
            // bringing this view back) would call load(_:) again and send another billed
            // request, even though the first one already succeeded or is still in flight.
            guard !hasStartedOwnLoad else { return }

            hasStartedOwnLoad = true
            source.adLoader.load(source.request)

            return
        }

        guard advertisementLoader == nil else { return }

        advertisementLoader = loader

        loader.lend(for: adUnitId, requester: ObjectIdentifier(self)) { [weak self] phase in
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
