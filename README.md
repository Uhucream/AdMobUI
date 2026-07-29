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
.onImpressionRecorded { /* an impression was recorded */ }
.onWillPresent { /* the ad is about to present a full screen view */ }
.onWillDismiss { /* the ad's full screen view is about to be dismissed */ }
.onDismiss { /* the ad's full screen view was dismissed */ }
.onAdvertisementMuted { /* the ad was muted */ }
```

These modifiers must be applied directly on `NativeAdvertisement`, before any standard SwiftUI modifier (such as `.listRowInsets`) that erases the concrete type.

## Reusing ads in a feed

`NativeAdvertisement(adUnitId:adContent:)` borrows an already-loaded ad from a shared `NativeAdvertisementLoader` instead of always requesting a new one. This matters in a `List` or `LazyVStack`: SwiftUI destroys and recreates a cell as it scrolls out and back into view, so without reuse, every reappearance would send a new (billed, rate-limited) ad request. This is the default behavior — no code changes are required to benefit from it.

To configure the shared loader (for example, to preload several ads per request), create one and apply it to the relevant view subtree:

```swift
var configuration: NativeAdvertisementLoader.Configuration = .default
configuration.numberOfAdvertisements = 5

let loader = NativeAdvertisementLoader(configuration: configuration)

List {
    ForEach(items) { item in
        Row(item)
        NativeAdvertisement(adUnitId: "ca-pub-xxxxxx") { advertisementPhase in
            // ....
        }
    }
}
.nativeAdvertisementLoader(loader)
```

`numberOfAdvertisements` (1 through 5) requests several ads in a single network round trip. Requesting more than one only serves Google ads — mediated networks don't participate in a multi-ad request — so raise it only when that trade-off is acceptable. Ads are dropped after roughly an hour, matching AdMob's own validity window for a loaded native ad.

Passing an explicit `request:` (and `options:`) to `NativeAdvertisement` opts that view out of the shared loader: the loader's ads were all loaded with the loader's own request, so reusing one for a view that asked for a different request would silently ignore it. Use the shared loader for a feed, and the `request:` initializers for one-off ads with their own targeting.

