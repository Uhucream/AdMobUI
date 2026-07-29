//
//  NativeAdvertisement.swift
//  AdMob-SwiftUI
//
//  Created by Takashi Ushikoshi on 2025/07/09.
//
//

import SwiftUI

public struct NativeAdvertisement<AdContent: View>: View {
    @StateObject private var nativeAdvertisementBinder: NativeAdvertisementBinder
    @Environment(\.nativeAdvertisementLoader) private var nativeAdvertisementLoader: NativeAdvertisementLoader?

    private let adUnitId: String

    @ViewBuilder private let adContent: (_ advertisementPhase: NativeAdvertisementPhase) -> AdContent

    private var onTapAction: (() -> Void)?
    private var onSwipeGestureAction: (() -> Void)?
    private var onImpressionRecordedAction: (() -> Void)?
    private var onWillPresentAction: (() -> Void)?
    private var onWillDismissAction: (() -> Void)?
    private var onDismissAction: (() -> Void)?
    private var onAdvertisementMutedAction: (() -> Void)?

    /// Displays a native ad for `adUnitId`.
    ///
    /// A view that reappears without a new identity, such as scrolling back into view in a
    /// `List` or `LazyVStack`, reuses the ad it already has instead of sending another request.
    ///
    /// The ad comes from the ``NativeAdvertisementLoader`` applied to this view's subtree with
    /// ``SwiftUICore/View/nativeAdvertisementLoader(_:)``, or from ``NativeAdvertisementLoader/shared`` when none
    /// has been applied.
    public init(
        adUnitId: String,
        @ViewBuilder adContent: @escaping (_ advertisementPhase: NativeAdvertisementPhase) -> AdContent
    ) {
        self.adUnitId = adUnitId
        self.adContent = adContent

        _nativeAdvertisementBinder = StateObject(
            wrappedValue: NativeAdvertisementBinder(adUnitId: adUnitId)
        )
    }

    public var body: some View {
        adContent(nativeAdvertisementBinder.nativeAdvertisementPhase)
            .coordinateSpace(name: NativeAdvertisementCoordinateSpaceName())
            .overlayPreferenceValue(ElementFramePreferenceKey.self, alignment: .center) { elementFrames in
                GeometryReader { overlayGeometry in
                    _RepresentedUINativeAdView(
                        nativeAd: nativeAdvertisementBinder.nativeAdvertisementPhase.nativeAd,
                        elementFrames: elementFrames,
                        onTapAction: onTapAction,
                        onSwipeGestureAction: onSwipeGestureAction,
                        onImpressionRecordedAction: onImpressionRecordedAction,
                        onWillPresentAction: onWillPresentAction,
                        onWillDismissAction: onWillDismissAction,
                        onDismissAction: onDismissAction,
                        onAdvertisementMutedAction: onAdvertisementMutedAction
                    )
                    .frame(width: overlayGeometry.size.width, height: overlayGeometry.size.height)
                }
            }
            .onAppear {
                nativeAdvertisementBinder.loadAd(with: nativeAdvertisementLoader ?? .shared)
            }
    }
}

extension NativeAdvertisement {
    /// Adds an action to perform when a click is recorded on the ad.
    /// - Parameter action: The action to perform.
    public func onTap(perform action: @escaping () -> Void) -> Self {
        var view: Self = self

        view.onTapAction = action

        return view
    }

    /// Adds an action to perform when a swipe gesture click is recorded on the ad.
    /// - Parameter action: The action to perform.
    public func onSwipeGesture(perform action: @escaping () -> Void) -> Self {
        var view: Self = self

        view.onSwipeGestureAction = action

        return view
    }

    /// Adds an action to perform when an impression is recorded on the ad.
    /// - Parameter action: The action to perform.
    public func onImpressionRecorded(perform action: @escaping () -> Void) -> Self {
        var view: Self = self

        view.onImpressionRecordedAction = action

        return view
    }

    /// Adds an action to perform before the ad presents a full screen view.
    /// - Parameter action: The action to perform.
    public func onWillPresent(perform action: @escaping () -> Void) -> Self {
        var view: Self = self

        view.onWillPresentAction = action

        return view
    }

    /// Adds an action to perform before the ad's full screen view is dismissed.
    /// - Parameter action: The action to perform.
    public func onWillDismiss(perform action: @escaping () -> Void) -> Self {
        var view: Self = self

        view.onWillDismissAction = action

        return view
    }

    /// Adds an action to perform after the ad's full screen view is dismissed.
    /// - Parameter action: The action to perform.
    public func onDismiss(perform action: @escaping () -> Void) -> Self {
        var view: Self = self

        view.onDismissAction = action

        return view
    }

    /// Adds an action to perform when the ad is muted.
    /// - Parameter action: The action to perform.
    public func onAdvertisementMuted(perform action: @escaping () -> Void) -> Self {
        var view: Self = self

        view.onAdvertisementMutedAction = action

        return view
    }
}
