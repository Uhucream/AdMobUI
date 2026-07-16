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

extension ElementFrame: Equatable {}

internal struct _RepresentedUINativeAdView: UIViewRepresentable {
    typealias UIViewType = _UINativeAdView

    internal let nativeAd: NativeAd?
    internal let elementFrames: [ElementFrame]

    internal func makeUIView(context: Context) -> _UINativeAdView {
        let nativeAdView = _UINativeAdView()
        nativeAdView.backgroundColor = .clear
        nativeAdView.isUserInteractionEnabled = true

        return nativeAdView
    }

    internal func updateUIView(_ nativeAdView: _UINativeAdView, context: Context) {
        guard let nativeAd else { return }

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
                        nativeAdView.headlineView = headlineView
                        nativeAdView.addSubview(headlineView)
                        return headlineView
                    }
                case .callToAction:
                    if let callToActionView = nativeAdView.callToActionView {
                        return callToActionView
                    } else {
                        let callToActionView = UIView()
                        nativeAdView.callToActionView = callToActionView
                        nativeAdView.addSubview(callToActionView)
                        return callToActionView
                    }
                case .icon:
                    if let iconView = nativeAdView.iconView {
                        return iconView
                    } else {
                        let iconView = UIView()
                        nativeAdView.iconView = iconView
                        nativeAdView.addSubview(iconView)
                        return iconView
                    }
                case .body:
                    if let bodyView = nativeAdView.bodyView {
                        return bodyView
                    } else {
                        let bodyView = UIView()
                        nativeAdView.bodyView = bodyView
                        nativeAdView.addSubview(bodyView)
                        return bodyView
                    }
                case .store:
                    if let storeView = nativeAdView.storeView {
                        return storeView
                    } else {
                        let storeView = UIView()
                        nativeAdView.storeView = storeView
                        nativeAdView.addSubview(storeView)
                        return storeView
                    }
                case .price:
                    if let priceView = nativeAdView.priceView {
                        return priceView
                    } else {
                        let priceView = UILabel()
                        nativeAdView.priceView = priceView
                        nativeAdView.addSubview(priceView)
                        return priceView
                    }
                case .image:
                    if let imageView = nativeAdView.imageView {
                        return imageView
                    } else {
                        let imageView = UIImageView()
                        nativeAdView.imageView = imageView
                        nativeAdView.addSubview(imageView)
                        return imageView
                    }
                case .starRating:
                    if let starRatingView = nativeAdView.starRatingView {
                        return starRatingView
                    } else {
                        let starRatingView = UIImageView()
                        nativeAdView.starRatingView = starRatingView
                        nativeAdView.addSubview(starRatingView)
                        return starRatingView
                    }
                case .advertiser:
                    if let advertiserView = nativeAdView.advertiserView {
                        return advertiserView
                    } else {
                        let advertiserView = UILabel()
                        nativeAdView.advertiserView = advertiserView
                        nativeAdView.addSubview(advertiserView)
                        return advertiserView
                    }
                case .media:
                    if let mediaView = nativeAdView.mediaView {
                        return mediaView
                    } else {
                        let mediaView = MediaView()
                        nativeAdView.mediaView = mediaView
                        nativeAdView.addSubview(mediaView)
                        return mediaView
                    }
                case .adChoices:
                    if let adChoicesView = nativeAdView.adChoicesView {
                        return adChoicesView
                    } else {
                        let adChoicesView = AdChoicesView()
                        nativeAdView.adChoicesView = adChoicesView
                        nativeAdView.addSubview(adChoicesView)
                        return adChoicesView
                    }
                }
            }()

            view.translatesAutoresizingMaskIntoConstraints = false
            view.isUserInteractionEnabled = false

            // Skip updating the constraints if the frame hasn't changed since the last time
            guard nativeAdView.lastAppliedElementFrames[type] != frame else { return }

            NSLayoutConstraint.deactivate(view.constraints)
            NSLayoutConstraint.activate([
                view.leadingAnchor.constraint(
                    equalTo: nativeAdView.leadingAnchor, constant: frame.origin.x),
                view.topAnchor.constraint(
                    equalTo: nativeAdView.topAnchor, constant: frame.origin.y),
                view.widthAnchor.constraint(equalToConstant: frame.width),
                view.heightAnchor.constraint(equalToConstant: frame.height),
            ])

            nativeAdView.lastAppliedElementFrames[type] = frame
        }

        // Set the NativeAd
        nativeAdView.nativeAd = nativeAd
    }
}

extension _RepresentedUINativeAdView: Equatable {
    internal static func == (lhs: _RepresentedUINativeAdView, rhs: _RepresentedUINativeAdView) -> Bool {
        guard lhs.elementFrames == rhs.elementFrames else { return false }

        switch (lhs.nativeAd, rhs.nativeAd) {
        case (nil, nil):
            return true

        case let (lhsNativeAd?, rhsNativeAd?):
            return lhsNativeAd === rhsNativeAd

        default:
            return false
        }
    }
}
