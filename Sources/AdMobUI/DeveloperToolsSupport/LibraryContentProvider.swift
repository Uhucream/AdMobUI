//
//  LibraryContentProvider.swift
//  AdMobUI
//
//  Created by Takashi Ushikoshi on 2026/07/31.
//
//

import DeveloperToolsSupport
import SwiftUI
@preconcurrency import GoogleMobileAds

struct LibraryContentProvider: DeveloperToolsSupport.LibraryContentProvider {
    @LibraryContentBuilder
    var views: [LibraryItem] {
        LibraryItem(
            NativeAdvertisement(adUnitId: /*@START_MENU_TOKEN@*/"Your Ad Unit ID"/*@END_MENU_TOKEN@*/) { advertisementPhase in
                if let nativeAd = advertisementPhase.nativeAd {
                    /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Ad Content@*/ /*@END_MENU_TOKEN@*/
                }
            },
            title: "Native Advertisement",
            category: .other
        )

        LibraryItem(
            NativeAdvertisement(adUnitId: /*@START_MENU_TOKEN@*/"Your Ad Unit ID"/*@END_MENU_TOKEN@*/) { advertisementPhase in
                switch advertisementPhase {
                case .empty:
                    EmptyView()

                case .success(let loadedAd):
                    VStack(alignment: .leading) {
                        if let headline = loadedAd.headline {
                            Text(headline)
                                .font(.headline)
                                .nativeAdElement(.headline)
                        }

                        AdvertisementMedia(mediaContent: loadedAd.mediaContent)
                    }

                case .failure:
                    EmptyView()
                }
            },
            title: "Native Advertisement (Full Phase Handling)",
            category: .other
        )
    }
}
