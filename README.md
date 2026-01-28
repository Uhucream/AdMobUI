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

## TODO

- [ ] Implement support to inject custom AdLoader implementations.
  ```swift
  NativeAdvertisement { loadedAd in
      // .... layout some ad
  }
  .environment(\.adLoader, CustomAdLoader())
  ```

- [] Improve performance
  
