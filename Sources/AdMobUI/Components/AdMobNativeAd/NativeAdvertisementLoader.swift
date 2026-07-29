//
//  NativeAdvertisementLoader.swift
//  AdMob-SwiftUI
//
//  Created by Takashi Ushikoshi on 2026/07/29.
//
//

import Combine
import Foundation
import GoogleMobileAds
import UIKit

/// Loads native ads once and hands out already-loaded ones to `NativeAdvertisement` views that
/// share the same ad unit id, instead of every view requesting its own.
public final class NativeAdvertisementLoader: NSObject {
    public static let shared: NativeAdvertisementLoader = .init(configuration: .default)

    private static let maximumRetentionInterval: TimeInterval = 55 * 60
    private static let expirationSweepInterval: TimeInterval = 5 * 60

    private let configuration: Configuration

    private var entriesByAdUnitId: [String: [Entry]] = [:]
    private var waitersByAdUnitId: [String: [Waiter]] = [:]
    private var activeAdLoadersByAdUnitId: [String: [AdLoader]] = [:]
    private var receivedAdvertisementCountsByAdLoader: [ObjectIdentifier: Int] = [:]
    private var lastErrorsByAdLoader: [ObjectIdentifier: any Error] = [:]
    private var cancellables: Set<AnyCancellable> = []

    public init(configuration: Configuration) {
        self.configuration = configuration

        super.init()

        NotificationCenter.default
            .publisher(for: UIApplication.didReceiveMemoryWarningNotification)
            .sink { [weak self] _ in
                self?.discardIdleAdvertisements()
            }
            .store(in: &cancellables)

        // purgeExpiredEntries(for:) only ever runs as a side effect of something asking to
        // lend/giveBack that specific ad unit id, so an ad unit id nobody touches for a while
        // would otherwise sit past its ~1 hour validity window unnoticed. These two sweep
        // every ad unit id proactively instead of waiting for the next lend/giveBack call.
        NotificationCenter.default
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.purgeAllExpiredEntries()
            }
            .store(in: &cancellables)

        Timer.publish(every: Self.expirationSweepInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.purgeAllExpiredEntries()
            }
            .store(in: &cancellables)
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
        maximumRetainedAdvertisements: 5
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
        for adUnitId: String,
        requester: ObjectIdentifier,
        onChange: @escaping (NativeAdvertisementPhase) -> Void
    ) {
        purgeExpiredEntries(for: adUnitId)

        if let availableEntryIndex = entriesByAdUnitId[adUnitId]?.firstIndex(where: { !$0.isLent }) {
            entriesByAdUnitId[adUnitId]?[availableEntryIndex].isLent = true

            onChange(.success(entriesByAdUnitId[adUnitId]![availableEntryIndex].nativeAd))

            return
        }

        waitersByAdUnitId[adUnitId, default: []].append(
            Waiter(requester: requester, onChange: onChange)
        )

        ensureLoadInFlight(for: adUnitId)
    }

    /// Withdraws a still-waiting `lend(for:requester:onChange:)` call, so a load that finishes
    /// later doesn't hand its result to a requester that's no longer interested.
    func cancelLending(requester: ObjectIdentifier, for adUnitId: String) {
        waitersByAdUnitId[adUnitId]?.removeAll { $0.requester == requester }
    }

    /// Returns an advertisement previously handed out by `lend(for:requester:onChange:)`, making
    /// it available to the next requester for the same ad unit id.
    func giveBack(_ nativeAd: NativeAd, for adUnitId: String) {
        guard let matchingEntryIndex = entriesByAdUnitId[adUnitId]?.firstIndex(where: { $0.nativeAd === nativeAd }) else {
            return
        }

        guard !isExpired(entriesByAdUnitId[adUnitId]![matchingEntryIndex]) else {
            entriesByAdUnitId[adUnitId]?.remove(at: matchingEntryIndex)

            // The entry being given back was the only candidate that could have served any
            // waiter registered for this ad unit id; without this, a waiter would sit stuck
            // forever if the ad handed back for reuse turned out to be expired.
            ensureLoadInFlight(for: adUnitId)

            return
        }

        entriesByAdUnitId[adUnitId]?[matchingEntryIndex].isLent = false

        serveWaiterIfPossible(for: adUnitId)
    }
}

extension NativeAdvertisementLoader {
    /// Requests as many advertisements for `adUnitId` as this loader's
    /// ``Configuration/maximumRetainedAdvertisements`` allows, so views that appear afterward
    /// can be served immediately instead of triggering a fresh load.
    public func prefetch(for adUnitId: String) {
        purgeExpiredEntries(for: adUnitId)

        while estimatedSupply(for: adUnitId) < effectiveMaximumRetainedAdvertisements,
              (activeAdLoadersByAdUnitId[adUnitId]?.count ?? 0) < configuration.maximumConcurrentLoads {
            startLoad(for: adUnitId)
        }
    }
}

extension NativeAdvertisementLoader {
    private func serveWaiterIfPossible(for adUnitId: String) {
        guard let waiter = waitersByAdUnitId[adUnitId]?.first else { return }
        guard let availableEntryIndex = entriesByAdUnitId[adUnitId]?.firstIndex(where: { !$0.isLent }) else {
            return
        }

        waitersByAdUnitId[adUnitId]?.removeFirst()
        entriesByAdUnitId[adUnitId]?[availableEntryIndex].isLent = true

        waiter.onChange(.success(entriesByAdUnitId[adUnitId]![availableEntryIndex].nativeAd))
    }

    private func ensureLoadInFlight(for adUnitId: String) {
        guard !(waitersByAdUnitId[adUnitId]?.isEmpty ?? true) else { return }

        guard (activeAdLoadersByAdUnitId[adUnitId]?.count ?? 0) < configuration.maximumConcurrentLoads else {
            return
        }

        startLoad(for: adUnitId)
    }

    private func startLoad(for adUnitId: String) {
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

    private func purgeExpiredEntries(for adUnitId: String) {
        // Only idle entries are dropped here. A lent entry stays valid until it's given back
        // (checked again in giveBack(_:for:)), since a view could currently be displaying it.
        entriesByAdUnitId[adUnitId]?.removeAll { !$0.isLent && isExpired($0) }
    }

    private func trimRetainedAdvertisements(for adUnitId: String) {
        guard var entries = entriesByAdUnitId[adUnitId] else { return }

        // Only idle entries can be dropped to respect effectiveMaximumRetainedAdvertisements,
        // for the same reason as purgeExpiredEntries(for:): a lent entry may still be on
        // screen. If every entry is lent, the cap is exceeded until one is given back.
        while entries.count > effectiveMaximumRetainedAdvertisements,
              let availableEntryIndex = entries.firstIndex(where: { !$0.isLent }) {
            entries.remove(at: availableEntryIndex)
        }

        entriesByAdUnitId[adUnitId] = entries
    }

    private func isExpired(_ entry: Entry) -> Bool {
        Date().timeIntervalSince(entry.loadedAt) > Self.maximumRetentionInterval
    }

    // A cap below numberOfAdvertisements would trim members of a batch that was just paid for
    // the moment it arrives, so the effective cap never goes below the batch size configured.
    private var effectiveMaximumRetainedAdvertisements: Int {
        max(configuration.maximumRetainedAdvertisements, configuration.numberOfAdvertisements)
    }

    private func estimatedSupply(for adUnitId: String) -> Int {
        let idleCount = entriesByAdUnitId[adUnitId]?.reduce(0) { $0 + ($1.isLent ? 0 : 1) } ?? 0
        let inFlightCount = (activeAdLoadersByAdUnitId[adUnitId]?.count ?? 0)
            * max(configuration.numberOfAdvertisements, 1)

        return idleCount + inFlightCount
    }
}

extension NativeAdvertisementLoader: NativeAdLoaderDelegate {
    public func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        let adUnitId = adLoader.adUnitID

        receivedAdvertisementCountsByAdLoader[ObjectIdentifier(adLoader), default: 0] += 1
        entriesByAdUnitId[adUnitId, default: []].append(
            Entry(nativeAd: nativeAd, loadedAt: Date(), isLent: false)
        )

        trimRetainedAdvertisements(for: adUnitId)
        serveWaiterIfPossible(for: adUnitId)
    }

    public func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: any Error) {
        lastErrorsByAdLoader[ObjectIdentifier(adLoader)] = error
    }

    public func adLoaderDidFinishLoading(_ adLoader: AdLoader) {
        let adUnitId = adLoader.adUnitID
        let receivedCount = receivedAdvertisementCountsByAdLoader.removeValue(forKey: ObjectIdentifier(adLoader)) ?? 0
        let lastError = lastErrorsByAdLoader.removeValue(forKey: ObjectIdentifier(adLoader))

        activeAdLoadersByAdUnitId[adUnitId]?.removeAll { $0 === adLoader }

        if receivedCount == 0, let waiters = waitersByAdUnitId[adUnitId], !waiters.isEmpty {
            // A load that came back completely empty is treated as terminal rather than
            // retried automatically: retrying here on every failure would spin an unbounded
            // stream of paid requests against an ad unit that's persistently failing. Every
            // waiter is failed instead, and the next retry only happens if the caller's own
            // onAppear-driven loadAd(with:) runs lend(for:requester:onChange:) again.
            waitersByAdUnitId[adUnitId] = []

            let error = lastError ?? NativeAdvertisementLoaderError.noAdvertisementReceived

            waiters.forEach { $0.onChange(.failure(error)) }

            return
        }

        ensureLoadInFlight(for: adUnitId)
    }
}

extension NativeAdvertisementLoader {
    private func discardIdleAdvertisements() {
        for adUnitId in entriesByAdUnitId.keys {
            entriesByAdUnitId[adUnitId]?.removeAll { !$0.isLent }
        }
    }

    private func purgeAllExpiredEntries() {
        for adUnitId in entriesByAdUnitId.keys {
            purgeExpiredEntries(for: adUnitId)
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
