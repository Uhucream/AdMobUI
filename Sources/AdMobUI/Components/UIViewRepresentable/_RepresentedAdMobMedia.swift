//
//  _RepresentedAdMobMedia.swift
//  AdMob-SwiftUI
//
//  Created by Takashi Ushikoshi on 2025/07/09.
//
//

import GoogleMobileAds
import SwiftUI

internal struct _RepresentedAdMobMedia: UIViewRepresentable {
    typealias UIViewType = UIView

    private let mediaContent: MediaContent?

    internal init(mediaContent: MediaContent?) {
        self.mediaContent = mediaContent
    }

    internal func makeUIView(context: Context) -> UIViewType {
        let containerView: UIViewType = .init()
        containerView.translatesAutoresizingMaskIntoConstraints = true
        containerView.backgroundColor = .clear

        let mediaView: MediaView = .init()
        mediaView.translatesAutoresizingMaskIntoConstraints = true
        mediaView.backgroundColor = .clear

        mediaView.autoresizingMask = [.flexibleWidth, .flexibleHeight]  // ← SwiftUIからサイズを受ける
        mediaView.frame = containerView.bounds

        containerView.addSubview(mediaView)

        return containerView
    }

    internal func updateUIView(_ uiView: UIViewType, context: Context) {
        guard let mediaView = uiView.subviews.first as? MediaView else { return }

        mediaView.mediaContent = mediaContent
    }
}
