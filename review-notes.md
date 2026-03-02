# Over the Horizon — Full App Review
*Reviewed 2026-03-02*

---

## Summary

Solid foundation with clean architecture and good test coverage for geometry/math. However, there are two critical bugs that undermine the app's core functionality: **the heading calculation is broken** (doesn't use compass) and **test file won't compile** (wrong initializer signatures). Several important issues with battery efficiency, search quality, and a data race also need attention.

---

## 🔴 Critical

### 1. Heading is NOT compass-based — core feature is broken
**File:** `MotionManager.swift`

`startDeviceMotionUpdates(to: .main)` uses the default reference frame `.xArbitraryZVertical` — an arbitrary frame with no relationship to magnetic north. `calculateHeading()` computes from `attitude.yaw`, but that yaw is relative to wherever the phone was pointed when the app launched.

AR labels are positioned relative to the phone's initial orientation, not compass north. Pointing north vs south shows the same labels in the same screen positions.

**Fix:** Use `startDeviceMotionUpdates(using: .xMagneticNorthZVertical, to: .main)`, OR add heading support to `LocationManager` using `CLLocationManager.startUpdatingHeading()` which gives True/Magnetic heading directly (simpler and more reliable).

### 2. Test file won't compile — wrong initializer signatures
**File:** `OverTheHorizonTests.swift`

`AROverlayView` requires `zoomGestureManager:` but tests call it without:
```swift
let view = AROverlayView(pois: [poi], heading: 0.0)  // missing zoomGestureManager
```

`POILabelView` requires `adjustedPosition:` and `zIndex:` but tests omit them:
```swift
let view = POILabelView(poi: poi, heading: 0.0, positioner: positioner)  // missing params
```

These tests fail to compile. Update to match actual initializers.

---

## 🟡 Important

### 3. POI search uses natural language instead of category filters
**File:** `POISearchManager.swift`

```swift
searchRequest.naturalLanguageQuery = category.rawValue  // "landmark", "museum"...
```

`LocationCategory` already has `mkCategory` mapping to `MKPointOfInterestCategory`. Natural language is noisy and slow. Use `MKLocalPointsOfInterestRequest` with `pointOfInterestFilter` instead.

### 4. Dead/misleading variable in MotionManager
**File:** `MotionManager.swift`

```swift
private let locationManager = CoreMotion.CMHeadingFilterValueDefault
```
Stores the Double constant 1.0 in a variable named `locationManager`. Never used. Delete it.

### 5. Redundant DispatchQueue.main.async in MotionManager
**File:** `MotionManager.swift`

`startDeviceMotionUpdates(to: .main)` already delivers on main. The inner `DispatchQueue.main.async` is redundant and misleading.

### 6. Concurrent search race condition
**File:** `POISearchManager.swift`

`searchPOIs()` can be called concurrently from the timer, settings dismissal, and init. The `isSearching` flag is set asynchronously and doesn't prevent concurrent execution. Two searches racing to write `self.pois` is wasteful and can produce inconsistent state. Add an `isSearching` guard at the top of `searchPOIs()`.

### 7. Settings always trigger full re-search on dismiss
**File:** `ContentView.swift`

`onDisappear` on SettingsView fires a full POI search every time, even if nothing changed. Cache enabled categories before presenting the modal and only re-search if they changed.

### 8. Info.plist declares Always Location permission but only WhenInUse is requested
**File:** `Info.plist`, `LocationManager.swift`

`NSLocationAlwaysAndWhenInUseUsageDescription` is present but the code only calls `requestWhenInUseAuthorization()`. Apple may flag this. Remove it unless background location is actually needed.

### 9. POI bearing/distance goes stale between searches
**File:** `POILocation.swift`

Bearing and distance are fixed at search time. With a 500m threshold and 30s timer, a user walking briskly will see AR labels pointing wrong directions. Bearing should be recomputed each frame from current `userLocation`.

### 10. Initial search fires before location permission is granted
**File:** `POISearchManager.swift`

`setupPeriodicSearch()` calls `searchPOIs()` immediately in init, before any permission has been requested. This always shows a red "Error: User location not available" on first launch. Show a neutral loading state instead.

---

## 🔵 Suggestions

### 11. screenSize starts at .zero — first-frame label flash
`@State private var screenSize: CGSize = .zero` means all labels start at (0,0) until `onAppear`. Guard against zero size before rendering labels.

### 12. SettingsManager async init inconsistency
`loadEnabledCategories()` sets `enabledCategories` via `DispatchQueue.main.async`. Right after `init()` returns, `enabledCategories` is empty. Set it synchronously in init.

### 13. ContentView @StateObject property declaration redundancy
Properties declared with `= LocationManager()` and then overridden in `init()`. The default values are dead code. Declare as `@StateObject private var locationManager: LocationManager` (no default) to avoid confusion.

### 14. No visual feedback in AR overlay when 0 POIs visible
When no POIs are in the FOV, the overlay is completely transparent. A subtle indicator would help users understand the app is working.

### 15. Zoom UX direction is counterintuitive
Pinch out = see farther (opposite of typical map behavior where pinch out = zoom in). Worth noting and potentially adding a preference.

---

## ✅ What's Done Well

- **Clean separation of concerns** — managers are well-isolated.
- **Overlap resolution** — priority-based vertical offset resolver handles edge cases correctly.
- **POI scoring** — weighted multi-factor scoring is well-designed.
- **Test coverage breadth** — good coverage of geometry, zoom, settings, and overlap (modulo compile errors).
- **Privacy** — only required permissions; all data stays on-device. ✓
- **ZoomGestureManager** — incremental gesture delta calculation avoids cumulative drift. ✓
- **Memory management** — `[weak self]` used consistently in async callbacks. ✓
