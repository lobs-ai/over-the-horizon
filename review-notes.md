# Over the Horizon — Full App Review

**Reviewed:** 2026-03-02  
**Scope:** Code quality, correctness, performance, spec compliance, privacy, UX

---

## Summary

The app is well-structured with clean separation of concerns. Core architecture (CameraManager, LocationManager, POISearchManager, ARLabelPositioner, OverlapResolver, ZoomGestureManager, SettingsManager) is solid and sensible. Test coverage is impressively broad. However there are several critical issues that will cause incorrect AR behavior and prevent tests from compiling.

---

## 🔴 Critical

### 1. Wrong heading source — AR labels will point in the wrong direction

**File:** `MotionManager.swift`, `calculateHeading(from:)`

`CMAttitude.yaw` is the device's rotation relative to its **initial orientation at app launch**, not geographic north. This is NOT a compass heading. The AR label overlay must know which direction is north to correctly position "Museum to the NE." Using raw yaw means the heading reference resets every app launch and is meaningless as an azimuth.

The `roll` and `pitch` variables are declared but never used. The property `private let locationManager = CoreMotion.CMHeadingFilterValueDefault` is a `Double` constant named `locationManager` — dead confusing code.

**Fix:** Use `CLLocationManager.startUpdatingHeading()` and observe `CLHeading.trueHeading` — the standard for POI-overlay AR. Alternatively, use `motionManager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical)` to align yaw to magnetic north.

---

### 2. AROverlayView and POILabelView tests won't compile

**File:** `OverTheHorizonTests.swift` — multiple AROverlayView and POILabelView test instantiations

Tests call:
```swift
AROverlayView(pois: [poi], heading: 0.0)
```
But the actual struct requires:
```swift
AROverlayView(pois:, heading:, zoomGestureManager:)
```
`zoomGestureManager` is `@ObservedObject` and a required parameter. Similarly, `POILabelView` tests omit `adjustedPosition: CGPoint` and `zIndex: Int`.

These tests will fail to compile, making the entire test suite unrunnable.

---

## 🟡 Important

### 3. POI bearing and distance go stale as user moves

`bearing` and `distance` are computed at search time and stored as constants on `POILocation`. After the user walks any distance between search intervals (up to 500m or 30s), the bearing stored on each POI is wrong. Labels in the AR overlay will drift to incorrect positions.

**Fix:** Recompute bearing/distance dynamically from `locationManager.userLocation` on each AR frame, or at minimum on every significant location update. Store only `CLLocationCoordinate2D` on `POILocation` and compute the rest dynamically.

### 4. No POI deduplication across categories

Each category runs an independent `MKLocalSearch`. The same physical location (e.g., a place that qualifies as both "landmark" and "historic site") will appear multiple times in `pois`. Duplicates go through scoring and can stack as multiple overlapping labels at the same bearing.

**Fix:** Deduplicate after all category searches complete — by coordinate proximity (within ~50m) or by `(name, coordinate)` key.

### 5. First POI search fires before location permission is granted

`setupPeriodicSearch()` is called from `init()` which immediately schedules `searchPOIs()`. At that point `locationManager.userLocation` is nil — permission hasn't been requested yet. The first search always fails. The app gets real results only after the 30s timer (if user has location by then).

**Fix:** Don't auto-trigger the initial search in init. Trigger it reactively when `locationManager.userLocation` first becomes non-nil, or at least delay the initial call until after `requestLocationPermission()` has resolved.

### 6. `CameraPreviewView` uses deprecated `UIScreen.main.bounds`

`UIScreen.main` is deprecated in iOS 16+. On multi-scene environments (iPad Stage Manager), it returns wrong values.

**Fix:** Use `UIView(frame: .zero)` and size the view via Auto Layout / `updateUIView` bounds, or read bounds from the parent view.

---

## 🔵 Suggestion

### 7. `MKLocalSearch` uses text query instead of structured categories

`searchRequest.naturalLanguageQuery = category.rawValue` ("museum", "park", etc.) is text-based. The `mkCategory` property is fully implemented but never used. For iOS 17+, `MKLocalPointsOfInterestRequest` with `pointOfInterestFilter` using the structured MK categories gives more precise results with less noise.

### 8. ContentView redundantly double-declares @StateObject defaults

All `@StateObject` properties have default `= SomeClass()` initializers AND are overridden in `init()`. The declaration defaults are never evaluated. Remove the default values from declarations to avoid confusion.

### 9. SettingsManager async init timing quirk

`loadEnabledCategories()` sets `enabledCategories` via `DispatchQueue.main.async`. The dict is empty synchronously after init, only populated on the next main queue flush. In practice `?? true` fallback covers this, but it's a latent bug if any code reads synchronously before the async block fires.

### 10. Overlap resolver uses fixed 60pt label width for all names

Short names ("Park") and long names ("Ann Arbor Train Station") use the same 60pt overlap bound. Long labels will visually overlap even after the resolver says they're clear.

---

## ✅ What's Done Well

- **Architecture:** Clean SRP, good ObservableObject data flow, sensible component boundaries.
- **ARLabelPositioner:** Bearing wrap-around math is correct. Opacity fade and clipping scale add real polish.
- **Test coverage:** Unusually thorough for an iOS side project — bearing math, distance clamping, overlap priority, zoom bounds, settings persistence. The foundation is excellent; just needs compile fixes.
- **Privacy:** No external API calls, no PII storage. Only `WhenInUse` authorization. All POI data from on-device Apple Maps. ✅
- **Empty state handling:** POI list shows empty state. AR overlay shows nothing when heading is nil. ✅
- **ZoomGestureManager:** Correctly computes incremental gesture deltas from `lastMagnificationScale`, avoiding the common cumulative-vs-delta bug. ✅
- **Settings persistence:** UserDefaults storage + reload is correct and tested. ✅

---

## Priority

1. 🔴 Fix heading source (wrong POI azimuth = useless AR)
2. 🔴 Fix test compilation (AROverlayView + POILabelView missing params)
3. 🟡 Recompute POI bearing dynamically
4. 🟡 Deduplicate POIs
5. 🟡 Don't search before location available
6. 🟡 UIScreen.main.bounds deprecation
7. 🔵 Text query → structured MK categories
