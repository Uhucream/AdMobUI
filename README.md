# AdMobUI

AdMobUI allows you to create AdMob native ads with fully SwiftUI.

## How it works

AdMobUI works by overlaying an invisible [`NativeAdView`](https://developers.google.com/admob/ios/api/reference/Classes/GADNativeAdView) on top of a SwiftUI view given inside the `NativeAdvertisement` closure.  

Each element of the native ad provided to the closure can be annotated with the `nativeAdElement` modifier, which automatically aligns and sizes the transparent [`NativeAdView`](https://developers.google.com/admob/ios/api/reference/Classes/GADNativeAdView) overlay.  

Internally, `nativeAdElement` uses `anchorPreference` and `overlayPreferenceValue` to capture the bounds of the annotated elements, enabling the layout of [`NativeAdView`](https://developers.google.com/admob/ios/api/reference/Classes/GADNativeAdView) to be computed automatically.

## Example

AdMobUI provides a `NativeAdvertisement` view that you can use to display native ads in your SwiftUI applications. You can customize the appearance of the ad by providing a closure that returns a view with the ad's content.

```swift
import AdMobUI

struct ContentView: View {
    var body: some View {
        List {
            NativeAdvertisement(adUnitId: "ca-pub-xxxxxx") { advertisementPhase in
                if case .success(let loadedAd) = advertisementPhase {
                    HStack {
                        if let icon = loadedAd.icon.image {
                            Image(uiImage: icon)
                                .resizable()
                                .scaledtoFit()
                                .nativeAdElement(.icon) // You must annotate with `nativeAdElement(:_)`
                        }

                        VStack {
                            if let headline = loadedAd.headline {
                                Text(headline)
                                    .font(.headline)
                                    .nativeAdElement(.headline)  // You must annotate with `nativeAdElement(:_)`
                            }

                            if let body = loadedAd.body {
                                Text(body)
                                    .nativeAdElement(.body)  // You must annotate with `nativeAdElement(:_)`
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .listRowInsets(EdgeInsets())
        }
    }
}
```

## Customizing the request

`NativeAdvertisement` provides progressively disclosed initializers. Start with just an ad unit id, and reach for a custom `Request` (and ad loader options) only when you need them.

```swift
// Custom request
NativeAdvertisement(adUnitId: "ca-pub-xxxxxx", request: myRequest) { advertisementPhase in
    // ....
}

// Custom request and ad loader options
NativeAdvertisement(adUnitId: "ca-pub-xxxxxx", request: myRequest, options: myOptions) { advertisementPhase in
    // ....
}
```

## Ad event callbacks

Ad interaction events are delivered through modifiers on `NativeAdvertisement`.

```swift
NativeAdvertisement(adUnitId: "ca-pub-xxxxxx") { advertisementPhase in
    // ....
}
.onTap { /* a click was recorded */ }
.onSwipeGesture { /* a swipe gesture click was recorded */ }
.onWillAppear { /* the ad is about to present a full screen view */ }
.onWillDisappear { /* the ad's full screen view is about to be dismissed */ }
.onDismiss { /* the ad's full screen view was dismissed */ }
.onAdvertisementMuted { /* the ad was muted */ }
```

These modifiers must be applied directly on `NativeAdvertisement`, before any standard SwiftUI modifier (such as `.listRowInsets`) that erases the concrete type.

## TODO

- [ ] Improve performance for ad-dense feeds

  Today each `NativeAdvertisement` owns its own loader and requests an ad in
  `onAppear`. Inside a `List` / `LazyVStack`, cells are destroyed and recreated
  as they scroll, so the loader is rebuilt and a fresh ad is requested every
  time a cell scrolls back into view. Ad requests are billed and rate limited,
  so a long scrolling feed can issue far more requests than it shows ads.

  Direction:

  - Introduce an ad pool/cache keyed by ad unit id that holds already-loaded
    ads and hands them out to views, so scrolling reuses ads instead of
    re-requesting them.
  - Preload a batch in a single request with
    `GADMultipleAdsAdLoaderOptions.numberOfAds` (up to 5 per request) to cut
    round trips, rather than one request per cell.
  - Let a view consume an ad from the shared pool instead of owning a loader.
    This is a different, opt-in API surface from the per-view `request:` /
    `options:` initializers (a shared loader implies a shared request), so it
    should be designed as an additive layer that does not change the current
    simple usage.
  
