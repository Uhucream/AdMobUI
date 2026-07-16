//
//  _UINativeAdView.swift
//  AdMob-SwiftUI
//
//  Created by Takashi Ushikoshi on 2025/07/09.
//
//

import GoogleMobileAds
import SwiftUI

internal class _UINativeAdView: NativeAdView {
    internal var lastAppliedElementFrames: [NativeAdChildViewType: CGRect] = [:]
    internal var elementFittingConstraints: [NativeAdChildViewType: [NSLayoutConstraint]] = [:]

    private var superviewFittingConstraints: [NSLayoutConstraint] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        NSLayoutConstraint.deactivate(superviewFittingConstraints)
        superviewFittingConstraints = []

        guard let superview else { return }

        superviewFittingConstraints = [
            leadingAnchor.constraint(equalTo: superview.leadingAnchor),
            trailingAnchor.constraint(equalTo: superview.trailingAnchor),
            topAnchor.constraint(equalTo: superview.topAnchor),
            bottomAnchor.constraint(equalTo: superview.bottomAnchor),
        ]

        NSLayoutConstraint.activate(superviewFittingConstraints)
    }
}
