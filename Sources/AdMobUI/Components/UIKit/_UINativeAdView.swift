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
    internal var hasActivatedSuperviewFittingConstraints: Bool = false
    internal var lastAppliedElementFrames: [NativeAdChildViewType: CGRect] = [:]

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
