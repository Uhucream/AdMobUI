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
    private let source: Source?
    private var advertisementLoader: NativeAdvertisementLoader?
    private var delegateAdaptor: NativeAdLoaderDelegateAdaptor?
    private var hasStartedOwnLoad: Bool = false

    // deinit is nonisolated even on a @MainActor class, and @Published's synthesized accessor
    // can't be read from there (a plain stored property can). This mirrors just the part deinit
    // needs to decide between giving an advertisement back and cancelling a pending request.
    private var currentNativeAd: NativeAd?

    // Own-request path: drives its own AdLoader rather than borrowing from a shared
    // NativeAdvertisementLoader, because that loader's advertisements were all loaded with the
    // loader's own request — handing one to a view that asked for a different request would
    // silently ignore what was asked for.
    //
    // A dedicated NativeAdvertisementLoader instance is deliberately not used here either: its
    // init sets up pool machinery (expiry sweeps, a memory-warning subscription, and a repeating
    // 5 minute timer) that a single one-off advertisement has no use for.
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

        // Every stored property without a default is set by this point, so self can be
        // captured now.
        let delegateAdaptor = NativeAdLoaderDelegateAdaptor(
            onReceive: { [weak self] _, nativeAd in
                self?.nativeAdvertisementPhase = .success(nativeAd)
            },
            onFailure: { [weak self] _, error in
                self?.nativeAdvertisementPhase = .failure(error)
            },
            onFinishLoading: { _ in }
        )

        adLoader.delegate = delegateAdaptor
        self.delegateAdaptor = delegateAdaptor
    }

    // Shared-pool path: borrows an already-loaded advertisement from a NativeAdvertisementLoader
    // instead of requesting one, so a view reappearing in a List or LazyVStack doesn't send
    // another billed request. The loader arrives later, via loadAd(with:), because SwiftUI's
    // environment isn't readable until the view appears.
    init(adUnitId: String) {
        self.adUnitId = adUnitId
        self.source = nil
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
    fileprivate struct Source {
        let adLoader: AdLoader
        let request: Request
    }
}

extension NativeAdvertisementBinder {
    func loadAd(with loader: NativeAdvertisementLoader?) {
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

        // Reaching .shared only here keeps it from being created for a view on the own-request
        // path above, which never borrows from a pool.
        let sharedLoader: NativeAdvertisementLoader = loader ?? .shared

        advertisementLoader = sharedLoader

        sharedLoader.lend(for: adUnitId, requester: ObjectIdentifier(self)) { [weak self] phase in
            self?.nativeAdvertisementPhase = phase
        }
    }
}
