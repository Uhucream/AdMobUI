//
//  NativeAdChildViewType.swift
//  AdMobSwiftUI
//
//  Created by Takashi Ushikoshi on 2025/07/09.
//
//

public struct NativeAdChildViewType {
    private let id: String

    fileprivate init(id: String) {
        self.id = id
    }
}

extension NativeAdChildViewType: Hashable {}

extension NativeAdChildViewType {
    public static let headline: NativeAdChildViewType = .init(id: "headline")
    public static let callToAction: NativeAdChildViewType = .init(id: "callToAction")
    public static let icon: NativeAdChildViewType = .init(id: "icon")
    public static let body: NativeAdChildViewType = .init(id: "body")
    public static let store: NativeAdChildViewType = .init(id: "store")
    public static let price: NativeAdChildViewType = .init(id: "price")
    public static let image: NativeAdChildViewType = .init(id: "image")
    public static let starRating: NativeAdChildViewType = .init(id: "starRating")
    public static let advertiser: NativeAdChildViewType = .init(id: "advertiser")
    package static let media: NativeAdChildViewType = .init(id: "media")
    package static let adChoices: NativeAdChildViewType = .init(id: "adChoices")
}
