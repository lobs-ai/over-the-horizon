# Over the Horizon — Full App Review

**Reviewer:** Reviewer Agent  
**Date:** 2026-03-02  
**Scope:** Full codebase — spec compliance, Swift quality, performance, edge cases, UX, privacy

---

## Summary

The app's architecture is clean and well-organized. Separation of concerns across CameraManager, LocationManager, MotionManager, POISearchManager, ZoomGestureManager, and SettingsManager is solid. Test coverage for pure logic is extensive. However, there's one **critical correctness bug** in heading calculation that would make the entire AR overlay wrong in practice, plus a **test compilation failure** blocking the test suite.

---

## 🔴 Critical

### 1. MotionManager heading is wrong — labels will point in wrong directions

**File:** `MotionManager.swift`, `calculateHeading(from:)`

```swift
let heading = (yaw * 180.0 / Double.pi) + 180.0
```

`CMAttitude.yaw` is relative to the device's initial orientation when `startDeviceMotionUpdates` was called — not magnetic north. The call uses `startDeviceMotionUpdates(to:)` with no reference frame, defaulting to `CMAttitudeReferenceFrameXArbitraryZVertical` — an arbitrary reference, not compass-aligned.

This means AR labels will only point correctly by coincidence (if the user faces the same direction as when the app started). The entire AR value proposition breaks.

**Fix:** Either pass `using: .xMagneticNorthZVertical` to `startDeviceMotionUpdates`, or (better) get heading from `CLLocationManager.startUpdatingHeading()` and use CoreMotion only for smoothing/tilt correction. The `LocationManager` already exists and should be extended for heading.

Also: `private let locationManager = CoreMotion.CMHeadingFilterValueDefault` is a dead, misleading property (it's a float constant named "locationManager"). Remove it.

### 2. Test compilation failure — AROverlayViewTests and POILabelView tests use outdated init signatures

**File:** `OverTheHorizonTests.swift`

```swift
// Won't compile — missing zoomGestureManager parameter
let view = AROverlayView(pois: [poi], heading: 0.0)

// Won't compile — missing adjustedPosition and zIndex parameters  
let view = POILabelView(poi: poi, heading: 0.0, positioner: positioner)
```

Current `AROverlayView` requires `zoomGestureManager: ZoomGestureManager`. Current `POILabelView` requires `adjustedPosition: CGPoint` and `zIndex: Int`. Tests haven't been updated. This blocks the entire test suite from compiling.

---

## 🟡 Important

### 3. ContentView init creates redundant objects

**File:** `ContentView.swift`

Property declarations like `@StateObject private var cameraManager = CameraManager()` are evaluated before `init()` runs, creating objects that are immediately discarded when `init()` re-assigns them. Five StateObjects are created twice on every ContentView initialization. Use typed declarations without initializers for properties overridden in `init()`:

```swift
@StateObject private var cameraManager: CameraManager  // no = CameraManager()
```

### 4. Privacy — unnecessary NSLocationAlwaysAndWhenInUseUsageDescription key

**File:** `Info.plist`

The app only calls `requestWhenInUseAuthorization()`. Including `NSLocationAlwaysAndWhenInUseUsageDescription` without ever requesting always-on access violates App Store review guidelines and may cause rejection. Remove the key.

### 5. OverlapResolver uses fixed 60pt label width — long names will still overlap

**File:** `OverlapResolver.swift`

```swift
private let minLabelWidth: CGFloat = 60.0
```

"Philadelphia Museum of Art" is treated as 60pt wide, same as "Zoo". In urban areas with long venue names, overlap detection fails. Estimate width from name length (e.g., `max(60, name.count * 8)`) or use a conservative fixed value of 150–200pt.

### 6. Zoom debug label has wrong unit

**File:** `ContentView.swift`

```swift
Text(String(format: "Zoom: %.2f (%.0f - %.0fm)", 
    zoomGestureManager.zoomLevel,
    zoomGestureManager.minDistance,
    zoomGestureManager.maxDistance / 1000))  // divided by 1000 but label says "m"
```

The max distance is divided by 1000 (yielding km) but the format string says `m`. At default zoom, this shows "100 - 50m" when it should show "100m - 50km".

---

## 🔵 Suggestions

### 7. POISearchManager fires initial search before location is available

`setupPeriodicSearch()` called from `init()` immediately dispatches `searchPOIs()`. This always fails with "User location not available" on launch (location permission hasn't been granted yet). The error flashes in the UI briefly. Consider waiting for first non-nil location before initiating the first search.

### 8. CameraPreviewView uses deprecated UIScreen.main.bounds (iOS 16+)

Use `.zero` for the initial frame instead.

### 9. POILabelView performs redundant shouldShowPOI() check

`displayedPOIs` in `AROverlayView` already filters by `shouldDisplay()`. `POILabelView.shouldShowPOI()` repeats the check unnecessarily. Remove it.

### 10. Optimal scoring distance at 25km feels off

`POIScorer.optimalDistance` is the midpoint of 100m–50km, i.e., 25km. POIs ~25km away score highest on the distance dimension. Most users want prominent *nearby* landmarks. Consider an optimal around 2–5km with a longer falloff tail.

---

## What's Done Well

- **Architecture is clean** — each manager has one responsibility, no god objects
- **Bearing normalization** is correct at the 0/360 wrap-around boundary in all relevant places
- **Test coverage is extensive** for pure logic (ARLabelPositioner, POIScorer, ZoomGestureManager, OverlapResolver, SettingsManager) — well above typical
- **Privacy is minimal** — camera, location, motion only; no external analytics or third-party SDKs
- **Settings persistence** via UserDefaults is clean and correct
- **Zoom gesture handling** uses proper incremental delta pattern, correctly converting cumulative gesture scale to per-frame deltas
- **POIScorer weights** (category 35%, distance 25%, prominence 25%, directional 15%) are reasonable for an AR POI display

---

## Priority File List

1. `MotionManager.swift` — 🔴 heading bug
2. `OverTheHorizonTests.swift` — 🔴 compile failures  
3. `ContentView.swift` — 🟡 duplicate init allocations
4. `Info.plist` — 🟡 remove always-location key
5. `OverlapResolver.swift` — 🟡 fixed label width
6. `ContentView.swift` — 🔵 zoom label unit bug
