//
//  ElementFittingConstraints.swift
//  AdMobUI
//
//  Created by Takashi Ushikoshi on 2026/07/29.
//
//

import UIKit

// Addressing each constraint by role, rather than by its position in an array, is what lets
// updateUIView adjust a moved element's constants in place instead of deactivating and
// recreating the whole set on every frame change.
internal struct ElementFittingConstraints {
    let leading: NSLayoutConstraint
    let top: NSLayoutConstraint
    let width: NSLayoutConstraint
    let height: NSLayoutConstraint
}

extension ElementFittingConstraints {
    var allConstraints: [NSLayoutConstraint] {
        [leading, top, width, height]
    }
}
