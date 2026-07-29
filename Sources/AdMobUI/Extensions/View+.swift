//
//  View+.swift
//  AdMobSwiftUI
//
//  Created by Takashi Ushikoshi on 2025/07/09.
//
//

import SwiftUI

extension View {
    public func nativeAdElement(_ elementViewType: NativeAdChildViewType) -> some View {
        anchorPreference(key: TypedAnchorBoundsPreferenceKey.self, value: .bounds) { anchor in
            return [TypedAnchor(viewType: elementViewType, anchor: anchor)]
        }
    }
}

extension View {
    /// A modifier that makes every `NativeAdvertisement` in this view's subtree load its
    /// advertisement through `loader`, so an advertisement loaded for one view can be reused
    /// by another instead of each view requesting its own.
    public func nativeAdvertisementLoader(_ loader: NativeAdvertisementLoader) -> some View {
        environment(\.nativeAdvertisementLoader, loader)
    }
}

// nil rather than .shared, so merely reading this value doesn't build the shared loader and
// start the subscriptions and repeating timer its init sets up. Callers substitute .shared at
// the point they actually borrow an advertisement.
private struct NativeAdvertisementLoaderKey: EnvironmentKey {
    static let defaultValue: NativeAdvertisementLoader? = nil
}

extension EnvironmentValues {
    var nativeAdvertisementLoader: NativeAdvertisementLoader? {
        get { self[NativeAdvertisementLoaderKey.self] }
        set { self[NativeAdvertisementLoaderKey.self] = newValue }
    }
}
