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
    /// Makes `loader` available to every `NativeAdvertisement` in this view's subtree.
    public func nativeAdvertisementLoader(_ loader: NativeAdvertisementLoader) -> some View {
        environment(\.nativeAdvertisementLoader, loader)
    }
}

private struct NativeAdvertisementLoaderKey: EnvironmentKey {
    static let defaultValue: NativeAdvertisementLoader = .shared
}

extension EnvironmentValues {
    var nativeAdvertisementLoader: NativeAdvertisementLoader {
        get { self[NativeAdvertisementLoaderKey.self] }
        set { self[NativeAdvertisementLoaderKey.self] = newValue }
    }
}
