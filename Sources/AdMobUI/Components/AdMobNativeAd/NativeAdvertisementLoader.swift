//
//  NativeAdvertisementLoader.swift
//  AdMob-SwiftUI
//
//  Created by Takashi Ushikoshi on 2026/07/29.
//
//

import Foundation
import GoogleMobileAds
import UIKit

/// Loads native ads once and hands out already-loaded ones to `NativeAdvertisement` views that
/// share the same ad unit id, instead of every view requesting its own.
///
/// Use ``shared`` for the default behavior, or construct one with a ``Configuration`` and apply
/// it to a view subtree with `View.nativeAdvertisementLoader(_:)`.
public final class NativeAdvertisementLoader: NSObject {
    public static let shared: NativeAdvertisementLoader = .init(configuration: .default)

    private static let maximumRetentionInterval: TimeInterval = 55 * 60

    private let configuration: Configuration

    private var entriesByAdUnitId: [String: [Entry]] = [:]
    private var waitersByAdUnitId: [String: [Waiter]] = [:]
    private var activeAdLoadersByAdUnitId: [String: [AdLoader]] = [:]
    private var receivedAdvertisementCountsByAdLoader: [ObjectIdentifier: Int] = [:]
    private var lastErrorsByAdLoader: [ObjectIdentifier: any Error] = [:]

    public init(configuration: Configuration) {
        self.configuration = configuration

        super.init()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension NativeAdvertisementLoader {
    public struct Configuration {
        public var request: Request
        public var options: [GADAdLoaderOptions]

        /// The number of advertisements to request per network round trip.
        ///
        /// Valid values are 1 through 5. Requesting more than one serves Google ads only;
        /// mediated networks don't participate in a multi-ad request.
        public var numberOfAdvertisements: Int

        /// The maximum number of loads this loader keeps in flight at once, per ad unit id.
        public var maximumConcurrentLoads: Int

        /// The maximum number of not-currently-displayed advertisements this loader keeps per
        /// ad unit id before discarding the oldest ones.
        public var maximumRetainedAdvertisements: Int
    }
}

extension NativeAdvertisementLoader.Configuration {
    public static let `default`: NativeAdvertisementLoader.Configuration = .init(
        request: Request(),
        options: [GADAdLoaderOptions()],
        numberOfAdvertisements: 1,
        maximumConcurrentLoads: 3,
        maximumRetainedAdvertisements: 10
    )
}

extension NativeAdvertisementLoader {
    fileprivate struct Entry {
        let nativeAd: NativeAd
        let loadedAt: Date
        var isLent: Bool
    }

    fileprivate struct Waiter {
        let requester: ObjectIdentifier
        let onChange: (NativeAdvertisementPhase) -> Void
    }
}

extension NativeAdvertisementLoader {
    /// Hands out an already-loaded advertisement for `adUnitId` if one is available, or
    /// registers `onChange` to be called once a load started on the caller's behalf finishes.
    ///
    /// `onChange` may be called synchronously, before this method returns.
    func lend(
        forAdUnitId adUnitId: String,
        requester: ObjectIdentifier,
        onChange: @escaping (NativeAdvertisementPhase) -> Void
    ) {
        purgeExpiredEntries(forAdUnitId: adUnitId)

        if let index = entriesByAdUnitId[adUnitId]?.firstIndex(where: { !$0.isLent }) {
            entriesByAdUnitId[adUnitId]?[index].isLent = true

            onChange(.success(entriesByAdUnitId[adUnitId]![index].nativeAd))

            return
        }

        waitersByAdUnitId[adUnitId, default: []].append(
            Waiter(requester: requester, onChange: onChange)
        )

        ensureLoadInFlight(forAdUnitId: adUnitId)
    }

    /// Withdraws a still-waiting `lend(forAdUnitId:requester:onChange:)` call, so a load that
    /// finishes later doesn't hand its result to a requester that's no longer interested.
    func cancelLending(requester: ObjectIdentifier, forAdUnitId adUnitId: String) {
        waitersByAdUnitId[adUnitId]?.removeAll { $0.requester == requester }
    }

    /// Returns an advertisement previously handed out by `lend(forAdUnitId:requester:onChange:)`,
    /// making it available to the next requester for the same ad unit id.
    func giveBack(_ nativeAd: NativeAd, forAdUnitId adUnitId: String) {
        guard let index = entriesByAdUnitId[adUnitId]?.firstIndex(where: { $0.nativeAd === nativeAd }) else {
            return
        }

        guard !isExpired(entriesByAdUnitId[adUnitId]![index]) else {
            entriesByAdUnitId[adUnitId]?.remove(at: index)

            return
        }

        entriesByAdUnitId[adUnitId]?[index].isLent = false

        serveWaiterIfPossible(forAdUnitId: adUnitId)
    }
}

extension NativeAdvertisementLoader {
    private func serveWaiterIfPossible(forAdUnitId adUnitId: String) {
        guard let waiter = waitersByAdUnitId[adUnitId]?.first else { return }
        guard let index = entriesByAdUnitId[adUnitId]?.firstIndex(where: { !$0.isLent }) else { return }

        waitersByAdUnitId[adUnitId]?.removeFirst()
        entriesByAdUnitId[adUnitId]?[index].isLent = true

        waiter.onChange(.success(entriesByAdUnitId[adUnitId]![index].nativeAd))
    }

    private func ensureLoadInFlight(forAdUnitId adUnitId: String) {
        guard !(waitersByAdUnitId[adUnitId]?.isEmpty ?? true) else { return }

        guard (activeAdLoadersByAdUnitId[adUnitId]?.count ?? 0) < configuration.maximumConcurrentLoads else {
            return
        }

        startLoad(forAdUnitId: adUnitId)
    }

    private func startLoad(forAdUnitId adUnitId: String) {
        var options = configuration.options

        if configuration.numberOfAdvertisements > 1 {
            let multipleAdsOptions = MultipleAdsAdLoaderOptions()
            multipleAdsOptions.numberOfAds = configuration.numberOfAdvertisements

            options.append(multipleAdsOptions)
        }

        let adLoader = AdLoader(
            adUnitID: adUnitId,
            rootViewController: nil,
            adTypes: [.native],
            options: options
        )

        adLoader.delegate = self

        activeAdLoadersByAdUnitId[adUnitId, default: []].append(adLoader)

        adLoader.load(configuration.request)
    }

    private func purgeExpiredEntries(forAdUnitId adUnitId: String) {
        entriesByAdUnitId[adUnitId]?.removeAll { !$0.isLent && isExpired($0) }
    }

    private func trimRetainedAdvertisements(forAdUnitId adUnitId: String) {
        guard var entries = entriesByAdUnitId[adUnitId] else { return }

        while entries.count > configuration.maximumRetainedAdvertisements,
              let index = entries.firstIndex(where: { !$0.isLent }) {
            entries.remove(at: index)
        }

        entriesByAdUnitId[adUnitId] = entries
    }

    private func isExpired(_ entry: Entry) -> Bool {
        Date().timeIntervalSince(entry.loadedAt) > Self.maximumRetentionInterval
    }
}

extension NativeAdvertisementLoader: @preconcurrency NativeAdLoaderDelegate {
    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        let adUnitId = adLoader.adUnitID

        receivedAdvertisementCountsByAdLoader[ObjectIdentifier(adLoader), default: 0] += 1
        entriesByAdUnitId[adUnitId, default: []].append(
            Entry(nativeAd: nativeAd, loadedAt: Date(), isLent: false)
        )

        trimRetainedAdvertisements(forAdUnitId: adUnitId)
        serveWaiterIfPossible(forAdUnitId: adUnitId)
    }

    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: any Error) {
        lastErrorsByAdLoader[ObjectIdentifier(adLoader)] = error
    }

    func adLoaderDidFinishLoading(_ adLoader: AdLoader) {
        let adUnitId = adLoader.adUnitID
        let receivedCount = receivedAdvertisementCountsByAdLoader.removeValue(forKey: ObjectIdentifier(adLoader)) ?? 0
        let lastError = lastErrorsByAdLoader.removeValue(forKey: ObjectIdentifier(adLoader))

        activeAdLoadersByAdUnitId[adUnitId]?.removeAll { $0 === adLoader }

        guard receivedCount == 0, let waiters = waitersByAdUnitId[adUnitId], !waiters.isEmpty else {
            ensureLoadInFlight(forAdUnitId: adUnitId)

            return
        }

        waitersByAdUnitId[adUnitId] = []

        let error = lastError ?? NativeAdvertisementLoaderError.noAdvertisementReceived

        waiters.forEach { $0.onChange(.failure(error)) }
    }
}

extension NativeAdvertisementLoader {
    @objc
    private func handleMemoryWarning() {
        for adUnitId in entriesByAdUnitId.keys {
            entriesByAdUnitId[adUnitId]?.removeAll { !$0.isLent }
        }
    }
}

/// The ad loader finished a request without delivering an advertisement or reporting an error.
///
/// The underlying SDK documents at least one of those two outcomes per request, so this is a
/// defensive fallback rather than an expected case.
internal enum NativeAdvertisementLoaderError: Error {
    case noAdvertisementReceived
}
