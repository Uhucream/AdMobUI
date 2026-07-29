//
//  ElementFramePreferenceKey.swift
//  AdMobUI
//
//  Created by Takashi Ushikoshi on 2025/07/09.
//
//

import SwiftUI

internal struct ElementFramePreferenceKey: PreferenceKey {
    static var defaultValue: [ElementFrame] = []

    static func reduce(
        value: inout [ElementFrame],
        nextValue: () -> [ElementFrame]
    ) {
        // nextValue always returns single or no elements because the preference modifier inside
        // nativeAdElement(_:) attaches a value containing a single element.
        let nextValueElement = nextValue().first

        // If nextValueElement is nil, it means there are no new element frames to process.
        guard let nextValueElement else { return }

        // if the nextValueElement already exists in the value array,
        // update its frame instead of appending a new one.
        if let existingElementFrame = value.first(where: { $0.elementType == nextValueElement.elementType }) {
            let updatedElementFrame: ElementFrame = .init(
                elementType: existingElementFrame.elementType,
                frame: nextValueElement.frame
            )

            let existingElementRemovedFrames = value.filter { $0.elementType != existingElementFrame.elementType }

            value = existingElementRemovedFrames + [updatedElementFrame]

            return
        }

        value.append(nextValueElement)
    }
}
