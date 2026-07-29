//
//  ElementFrame.swift
//  AdMobUI
//
//  Created by Takashi Ushikoshi on 2026/07/29.
//
//

import CoreGraphics

internal struct ElementFrame {
    let elementType: NativeAdChildViewType

    // Measured in the coordinate space named on the advertisement container, so the value
    // never passes through the window-relative arithmetic that a resolved Anchor<CGRect> does.
    let frame: CGRect
}
