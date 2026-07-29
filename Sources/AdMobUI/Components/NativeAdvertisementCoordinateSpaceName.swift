//
//  NativeAdvertisementCoordinateSpaceName.swift
//  AdMobUI
//
//  Created by Takashi Ushikoshi on 2026/07/29.
//
//

// A dedicated type rather than a string, so a coordinate space the host app happens to name
// the same way can never end up resolving an element's frame against the wrong ancestor.
internal struct NativeAdvertisementCoordinateSpaceName: Hashable {}
