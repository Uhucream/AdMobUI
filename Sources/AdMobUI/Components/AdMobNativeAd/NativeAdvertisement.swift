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
    @StateObject private var nativeAdvertisementBinder: NativeAdvertisementBinder
    @Environment(\.nativeAdvertisementLoader) private var nativeAdvertisementLoader: NativeAdvertisementLoader

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

        _nativeAdvertisementBinder = StateObject(
            wrappedValue: NativeAdvertisementBinder(
                adUnitId: adUnitId,
                request: request,
                options: options
            )
        )
    }

    public var body: some View {
        adContent(nativeAdvertisementBinder.nativeAdvertisementPhase)
            .overlayPreferenceValue(TypedAnchorBoundsPreferenceKey.self, alignment: .center) { namedAnchors in
                GeometryReader { overlayGeometry in
                    let elementFrames: [ElementFrame] = namedAnchors.map {
                        .init(
                            elementType: $0.viewType,
                            frame: overlayGeometry[$0.anchor]
                        )
                    }

                    _RepresentedUINativeAdView(
                        nativeAd: nativeAdvertisementBinder.nativeAdvertisementPhase.nativeAd,
                        elementFrames: elementFrames,
                        onTapAction: onTapAction,
                        onSwipeGestureAction: onSwipeGestureAction,
                        onWillAppearAction: onWillAppearAction,
                        onWillDisappearAction: onWillDisappearAction,
                        onDismissAction: onDismissAction,
                        onAdvertisementMutedAction: onAdvertisementMutedAction
                    )
                    .frame(width: overlayGeometry.size.width, height: overlayGeometry.size.height)
                }
            }
            .onAppear {
                nativeAdvertisementBinder.loadAd(with: nativeAdvertisementLoader)
            }
    }
}

extension NativeAdvertisement {
    /// Displays a native ad for `adUnitId`, borrowing an already-loaded advertisement from the
    /// shared ``NativeAdvertisementLoader`` when one is available instead of always requesting a
    /// new one.
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

    /// Displays a native ad loaded with a caller-supplied request.
    ///
    /// This view drives its own request instead of borrowing from the shared
    /// ``NativeAdvertisementLoader``, since an advertisement from the shared loader was loaded
    /// with the loader's own request and reusing it here would silently ignore this one.
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

    /// Adds an action to perform before the ad presents a full screen view.
    /// - Parameter action: The action to perform.
    public func onWillAppear(perform action: @escaping () -> Void) -> Self {
        var view: Self = self

        view.onWillAppearAction = action

        return view
    }

    /// Adds an action to perform before the ad's full screen view is dismissed.
    /// - Parameter action: The action to perform.
    public func onWillDisappear(perform action: @escaping () -> Void) -> Self {
        var view: Self = self

        view.onWillDisappearAction = action

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
