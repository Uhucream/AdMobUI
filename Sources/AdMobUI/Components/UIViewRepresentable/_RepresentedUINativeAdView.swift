//
//  _RepresentedUINativeAdView.swift
//  AdMob-SwiftUI
//
//  Created by Takashi Ushikoshi on 2025/07/09.
//
//

import GoogleMobileAds
import SwiftUI

internal struct ElementFrame {
    let elementType: NativeAdChildViewType
    let frame: CGRect
}

internal struct _RepresentedUINativeAdView: UIViewRepresentable {
    typealias UIViewType = _UINativeAdView

    internal let nativeAd: NativeAd?
    internal let elementFrames: [ElementFrame]

    internal let onTapAction: (() -> Void)?
    internal let onSwipeGestureAction: (() -> Void)?
    internal let onImpressionRecordedAction: (() -> Void)?
    internal let onWillPresentAction: (() -> Void)?
    internal let onWillDismissAction: (() -> Void)?
    internal let onDismissAction: (() -> Void)?
    internal let onAdvertisementMutedAction: (() -> Void)?

    internal func makeUIView(context: Context) -> _UINativeAdView {
        let nativeAdView = _UINativeAdView()
        nativeAdView.backgroundColor = .clear
        nativeAdView.isUserInteractionEnabled = true

        return nativeAdView
    }

    internal func updateUIView(_ nativeAdView: _UINativeAdView, context: Context) {
        // Keep the coordinator's callbacks current even when the rest of this update is
        // skipped below (this replaces what `.equatable()` used to do at the view level).
        context.coordinator.parent = self

        guard let nativeAd else { return }

        let hasSameAdvertisement: Bool = nativeAdView.nativeAd === nativeAd
        let hasSameElementFrames: Bool =
            nativeAdView.lastAppliedElementFrames.count == elementFrames.count
            && elementFrames.allSatisfy { nativeAdView.lastAppliedElementFrames[$0.elementType] == $0.frame }

        guard !(hasSameAdvertisement && hasSameElementFrames) else { return }

        let currentElementTypes: Set<NativeAdChildViewType> = Set(elementFrames.map(\.elementType))
        let staleElementTypes: Set<NativeAdChildViewType> = Set(nativeAdView.lastAppliedElementFrames.keys)
            .subtracting(currentElementTypes)

        // Remove elements no longer present in the current SwiftUI layout, so a stale
        // tracking view doesn't keep sitting at its last known position/size and
        // doesn't keep being registered as a clickable/trackable asset on the NativeAd.
        staleElementTypes.forEach { type in
            removeElementView(for: type, from: nativeAdView)

            NSLayoutConstraint.deactivate(nativeAdView.elementFittingConstraints[type] ?? [])
            nativeAdView.elementFittingConstraints[type] = nil
            nativeAdView.lastAppliedElementFrames[type] = nil
        }

        // Update and add each element view
        elementFrames.forEach { elementFrame in
            let type: NativeAdChildViewType = elementFrame.elementType
            let frame: CGRect = elementFrame.frame

            let view: UIView = {
                switch type {
                case .headline:
                    if let headlineView = nativeAdView.headlineView {
                        return headlineView
                    } else {
                        let headlineView = UIView()
                        headlineView.isUserInteractionEnabled = false
                        nativeAdView.headlineView = headlineView
                        nativeAdView.addSubview(headlineView)
                        return headlineView
                    }
                case .callToAction:
                    if let callToActionView = nativeAdView.callToActionView {
                        return callToActionView
                    } else {
                        let callToActionView = UIView()
                        callToActionView.isUserInteractionEnabled = false
                        nativeAdView.callToActionView = callToActionView
                        nativeAdView.addSubview(callToActionView)
                        return callToActionView
                    }
                case .icon:
                    if let iconView = nativeAdView.iconView {
                        return iconView
                    } else {
                        let iconView = UIView()
                        iconView.isUserInteractionEnabled = false
                        nativeAdView.iconView = iconView
                        nativeAdView.addSubview(iconView)
                        return iconView
                    }
                case .body:
                    if let bodyView = nativeAdView.bodyView {
                        return bodyView
                    } else {
                        let bodyView = UIView()
                        bodyView.isUserInteractionEnabled = false
                        nativeAdView.bodyView = bodyView
                        nativeAdView.addSubview(bodyView)
                        return bodyView
                    }
                case .store:
                    if let storeView = nativeAdView.storeView {
                        return storeView
                    } else {
                        let storeView = UIView()
                        storeView.isUserInteractionEnabled = false
                        nativeAdView.storeView = storeView
                        nativeAdView.addSubview(storeView)
                        return storeView
                    }
                case .price:
                    if let priceView = nativeAdView.priceView {
                        return priceView
                    } else {
                        let priceView = UILabel()
                        priceView.isUserInteractionEnabled = false
                        nativeAdView.priceView = priceView
                        nativeAdView.addSubview(priceView)
                        return priceView
                    }
                case .image:
                    if let imageView = nativeAdView.imageView {
                        return imageView
                    } else {
                        let imageView = UIImageView()
                        imageView.isUserInteractionEnabled = false
                        nativeAdView.imageView = imageView
                        nativeAdView.addSubview(imageView)
                        return imageView
                    }
                case .starRating:
                    if let starRatingView = nativeAdView.starRatingView {
                        return starRatingView
                    } else {
                        let starRatingView = UIImageView()
                        starRatingView.isUserInteractionEnabled = false
                        nativeAdView.starRatingView = starRatingView
                        nativeAdView.addSubview(starRatingView)
                        return starRatingView
                    }
                case .advertiser:
                    if let advertiserView = nativeAdView.advertiserView {
                        return advertiserView
                    } else {
                        let advertiserView = UILabel()
                        advertiserView.isUserInteractionEnabled = false
                        nativeAdView.advertiserView = advertiserView
                        nativeAdView.addSubview(advertiserView)
                        return advertiserView
                    }
                case .media:
                    let mediaView: MediaView

                    if let existingMediaView = nativeAdView.mediaView {
                        mediaView = existingMediaView
                    } else {
                        mediaView = MediaView()
                        // GADMediaView needs user interaction enabled to drive its own
                        // controls (e.g. the mute button).
                        mediaView.isUserInteractionEnabled = true
                        nativeAdView.mediaView = mediaView
                        nativeAdView.addSubview(mediaView)
                    }

                    // Unlike the other asset views, the media view renders its content
                    // itself, so it needs the media content assigned.
                    mediaView.mediaContent = nativeAd.mediaContent

                    return mediaView
                case .adChoices:
                    if let adChoicesView = nativeAdView.adChoicesView {
                        return adChoicesView
                    } else {
                        let adChoicesView = AdChoicesView()
                        adChoicesView.isUserInteractionEnabled = false
                        nativeAdView.adChoicesView = adChoicesView
                        nativeAdView.addSubview(adChoicesView)
                        return adChoicesView
                    }
                default:
                    // NativeAdChildViewType is a struct with a fixed set of values, so
                    // every case above is handled and this is unreachable.
                    fatalError("Unhandled NativeAdChildViewType")
                }
            }()

            view.translatesAutoresizingMaskIntoConstraints = false

            // Skip updating the constraints if the frame hasn't changed since the last time
            guard nativeAdView.lastAppliedElementFrames[type] != frame else { return }

            // view.constraints only holds constraints owned by view itself (e.g. width/height);
            // the leading/top constraints below are owned by their nearest common ancestor
            // (nativeAdView), so the constraints we installed last time must be tracked explicitly.
            NSLayoutConstraint.deactivate(nativeAdView.elementFittingConstraints[type] ?? [])

            let fittingConstraints: [NSLayoutConstraint] = [
                view.leadingAnchor.constraint(
                    equalTo: nativeAdView.leadingAnchor, constant: frame.origin.x),
                view.topAnchor.constraint(
                    equalTo: nativeAdView.topAnchor, constant: frame.origin.y),
                view.widthAnchor.constraint(equalToConstant: frame.width),
                view.heightAnchor.constraint(equalToConstant: frame.height),
            ]

            NSLayoutConstraint.activate(fittingConstraints)

            nativeAdView.elementFittingConstraints[type] = fittingConstraints
            nativeAdView.lastAppliedElementFrames[type] = frame
        }

        // The NativeAd instance only exists after the async load completes, so this is
        // the only point where its delegate can be set.
        nativeAd.delegate = context.coordinator

        // Set the NativeAd
        nativeAdView.nativeAd = nativeAd
    }

    internal func dismantleUIView(_ nativeAdView: _UINativeAdView, context: Context) {
        // An ad returned to a shared NativeAdvertisementLoader can be lent straight back out to
        // a different view; unregistering here keeps that reuse from carrying over this view's
        // asset-view associations.
        nativeAdView.nativeAd?.unregisterAdView()
    }

    internal func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

extension _RepresentedUINativeAdView {
    internal final class Coordinator: NSObject {
        fileprivate var parent: _RepresentedUINativeAdView

        init(_ parent: _RepresentedUINativeAdView) {
            self.parent = parent

            super.init()
        }
    }
}

extension _RepresentedUINativeAdView.Coordinator: NativeAdDelegate {
    // The callbacks are intentionally argument-less (() -> Void). The SDK passes the
    // nativeAd so a single delegate can tell multiple ads apart, but here one ad maps to
    // one delegate, so there is nothing to disambiguate.
    func nativeAdDidRecordClick(_ nativeAd: NativeAd) {
        parent.onTapAction?()
    }

    func nativeAdDidRecordSwipeGestureClick(_ nativeAd: NativeAd) {
        parent.onSwipeGestureAction?()
    }

    func nativeAdDidRecordImpression(_ nativeAd: NativeAd) {
        parent.onImpressionRecordedAction?()
    }

    func nativeAdWillPresentScreen(_ nativeAd: NativeAd) {
        parent.onWillPresentAction?()
    }

    func nativeAdWillDismissScreen(_ nativeAd: NativeAd) {
        parent.onWillDismissAction?()
    }

    func nativeAdDidDismissScreen(_ nativeAd: NativeAd) {
        parent.onDismissAction?()
    }

    func nativeAdIsMuted(_ nativeAd: NativeAd) {
        parent.onAdvertisementMutedAction?()
    }
}

extension _RepresentedUINativeAdView {
    private func removeElementView(for type: NativeAdChildViewType, from nativeAdView: _UINativeAdView) {
        switch type {
        case .headline:
            nativeAdView.headlineView?.removeFromSuperview()
            nativeAdView.headlineView = nil

        case .callToAction:
            nativeAdView.callToActionView?.removeFromSuperview()
            nativeAdView.callToActionView = nil

        case .icon:
            nativeAdView.iconView?.removeFromSuperview()
            nativeAdView.iconView = nil

        case .body:
            nativeAdView.bodyView?.removeFromSuperview()
            nativeAdView.bodyView = nil

        case .store:
            nativeAdView.storeView?.removeFromSuperview()
            nativeAdView.storeView = nil

        case .price:
            nativeAdView.priceView?.removeFromSuperview()
            nativeAdView.priceView = nil

        case .image:
            nativeAdView.imageView?.removeFromSuperview()
            nativeAdView.imageView = nil

        case .starRating:
            nativeAdView.starRatingView?.removeFromSuperview()
            nativeAdView.starRatingView = nil

        case .advertiser:
            nativeAdView.advertiserView?.removeFromSuperview()
            nativeAdView.advertiserView = nil

        case .media:
            nativeAdView.mediaView?.removeFromSuperview()
            nativeAdView.mediaView = nil

        case .adChoices:
            nativeAdView.adChoicesView?.removeFromSuperview()
            nativeAdView.adChoicesView = nil

        default:
            break
        }
    }
}
