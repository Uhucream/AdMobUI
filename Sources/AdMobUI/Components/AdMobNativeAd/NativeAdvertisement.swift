//
//  NativeAdvertisement.swift
//  AdMob-SwiftUI
//
//  Created by Takashi Ushikoshi on 2025/07/09.
//
//

import GoogleMobileAds
import SwiftUI

public struct NativeAdvertisement<AdContent: View>: View {
    @StateObject private var nativeAdLoader: NativeAdLoader

    private let adUnitId: String

    @ViewBuilder private let adContent: (_ advertisementPhase: NativeAdvertisementPhase) -> AdContent

    private var onTapAction: (() -> Void)?
    private var onSwipeGestureAction: (() -> Void)?
    private var onWillAppearAction: (() -> Void)?
    private var onWillDisappearAction: (() -> Void)?
    private var onDismissAction: (() -> Void)?
    private var onAdvertisementMutedAction: (() -> Void)?

    public init(
        adUnitId: String,
        request: Request,
        options: [GADAdLoaderOptions],
        @ViewBuilder adContent: @escaping (_ advertisementPhase: NativeAdvertisementPhase) -> AdContent
    ) {
        self.adUnitId = adUnitId
        self.adContent = adContent

        _nativeAdLoader = StateObject(
            wrappedValue: NativeAdLoader(
                adUnitId: adUnitId,
                request: request,
                options: options
            )
        )
    }

    public var body: some View {
        adContent(nativeAdLoader.nativeAdvertisementPhase)
            .overlayPreferenceValue(TypedAnchorBoundsPreferenceKey.self, alignment: .center) { namedAnchors in
                GeometryReader { overlayGeometry in
                    let elementFrames: [ElementFrame] = namedAnchors.map {
                        .init(
                            elementType: $0.viewType,
                            frame: overlayGeometry[$0.anchor]
                        )
                    }

                    _RepresentedUINativeAdView(
                        nativeAd: nativeAdLoader.nativeAdvertisementPhase.nativeAd,
                        elementFrames: elementFrames,
                        onTapAction: onTapAction,
                        onSwipeGestureAction: onSwipeGestureAction,
                        onWillAppearAction: onWillAppearAction,
                        onWillDisappearAction: onWillDisappearAction,
                        onDismissAction: onDismissAction,
                        onAdvertisementMutedAction: onAdvertisementMutedAction
                    )
                    .equatable()
                    .frame(width: overlayGeometry.size.width, height: overlayGeometry.size.height)
                }
            }
            .onAppear {
                nativeAdLoader.loadAd()
            }
    }
}

extension NativeAdvertisement {
    public init(
        adUnitId: String,
        @ViewBuilder adContent: @escaping (_ advertisementPhase: NativeAdvertisementPhase) -> AdContent
    ) {
        self.init(
            adUnitId: adUnitId,
            request: Request(),
            options: [GADAdLoaderOptions()],
            adContent: adContent
        )
    }

    public init(
        adUnitId: String,
        request: Request,
        @ViewBuilder adContent: @escaping (_ advertisementPhase: NativeAdvertisementPhase) -> AdContent
    ) {
        self.init(
            adUnitId: adUnitId,
            request: request,
            options: [GADAdLoaderOptions()],
            adContent: adContent
        )
    }
}

extension NativeAdvertisement {
    /// Registers a handler invoked when a click is recorded on the ad.
    public func onTap(perform action: @escaping () -> Void) -> Self {
        var view: Self = self

        view.onTapAction = action

        return view
    }

    /// Registers a handler invoked when a swipe gesture click is recorded on the ad.
    public func onSwipeGesture(perform action: @escaping () -> Void) -> Self {
        var view: Self = self

        view.onSwipeGestureAction = action

        return view
    }

    /// Registers a handler invoked when the ad is about to present a full screen view.
    public func onWillAppear(perform action: @escaping () -> Void) -> Self {
        var view: Self = self

        view.onWillAppearAction = action

        return view
    }

    /// Registers a handler invoked when the ad's full screen view is about to be dismissed.
    public func onWillDisappear(perform action: @escaping () -> Void) -> Self {
        var view: Self = self

        view.onWillDisappearAction = action

        return view
    }

    /// Registers a handler invoked after the ad's full screen view has been dismissed.
    public func onDismiss(perform action: @escaping () -> Void) -> Self {
        var view: Self = self

        view.onDismissAction = action

        return view
    }

    /// Registers a handler invoked when the ad is muted.
    public func onAdvertisementMuted(perform action: @escaping () -> Void) -> Self {
        var view: Self = self

        view.onAdvertisementMutedAction = action

        return view
    }
}
