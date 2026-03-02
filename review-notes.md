# Over the Horizon — Full App Review

**Date:** 2026-03-02  
**Reviewer:** Reviewer Agent  
**Scope:** Spec compliance, Swift quality, performance, edge cases, UX polish, privacy

---

## Summary

The codebase is well-structured and readable. The architecture separates concerns cleanly, naming is good, and the test suite is extensive. However, there are **two critical bugs** that would make the AR overlay fundamentally non-functional on a real device, plus compilation failures in tests.

---

## 🔴 Critical

### 1. Heading from CMAttitude.yaw is relative — not magnetic north

**File:** `MotionManager.swift`

`startDeviceMotionUpdates(to:)` without a reference frame defaults to `xArbitraryZVertical`. This means yaw=0 is wherever the device was pointing **when updates started**, not north. On a real device, AR overlays will point in the wrong direction unless the user happens to face north at launch.

**Fix:** Either use `startDeviceMotionUpdates(using: .xMagneticNorthZVertical)` (requires figure-8 calibration), or switch to `CLLocationManager.startUpdatingHeading()` in the existing `LocationManager` — simpler and more reliable.

### 2. AROverlayView tests won't compile — missing `zoomGestureManager` parameter

**File:** `OverTheHorizonTests.swift`

```swift
let view = AROverlayView(pois: [poi], heading: 0.0)  // missing required zoomGestureManager
```

`AROverlayView` requires `zoomGestureManager: ZoomGestureManager`. Classes `AROverlayViewTests` and `MaxDisplayLimitTests` all call the view without this parameter. These won't compile, so those test classes are dead weight.

---

## 🟡 Important

### 3. Initial POI search fires twice on launch

**File:** `POISearchManager.swift`

`init()` calls `setupPeriodicSearch()` which immediately fires a Task to search. Then `ContentView.onAppear` calls `startPeriodicSearch()` which calls `setupPeriodicSearch()` again — another immediate search plus a new timer. Result: 24 MKLocalSearch requests × 2 = 48 requests on launch.

**Fix:** Remove `setupPeriodicSearch()` from `init()`. Let `startPeriodicSearch()` be the explicit entry point from the view.

### 4. Settings categories not applied to the initial search

**File:** `POISearchManager.swift` / `ContentView.swift`

The initial and periodic searches always use `LocationCategory.allCases`. UserDefaults-persisted category preferences are only applied after the user opens and dismisses Settings. On relaunch, disabled categories reappear until the user touches Settings.

**Fix:** Pass `settingsManager.getEnabledCategories()` to the initial search, or inject `SettingsManager` into `POISearchManager`.

### 5. ContentView.init() creates duplicate StateObject instances

**File:** `ContentView.swift`

```swift
@StateObject private var cameraManager = CameraManager()  // instance #1, immediately discarded
// ...
init() {
    _cameraManager = StateObject(wrappedValue: CameraManager())  // instance #2
```

All six `@StateObject` properties are initialized at the declaration site AND in `init()`. Drop the `= Value()` at the declaration site when overriding in `init()`.

### 6. Misleading unused property in MotionManager

**File:** `MotionManager.swift`

```swift
private let locationManager = CoreMotion.CMHeadingFilterValueDefault
```

This stores `1.0` (a Double) in a property named `locationManager`. It's never used. Delete it before it causes real confusion.

### 7. Labels render at (0,0) on first frame

**File:** `AROverlayView.swift`

`screenSize` starts as `.zero`. `positioner` is a computed property using `screenSize`. On the first render pass, all label positions are calculated against a 0×0 screen. They correct after `onAppear`, but there's a flash.

**Fix:** Only render labels when `screenSize != .zero`, or use `GeometryReader` that initializes size before first render.

### 8. OverlapResolver uses hardcoded 60×24pt label bounds — actual labels vary widely

**File:** `OverlapResolver.swift`

Long POI names (e.g. "International Museum of Contemporary Art") will render far wider than 60pt. At zoom-in, font sizes can exceed 24pt × 3.3× multiplier. The resolver will declare overlapping labels as non-overlapping.

**Fix:** Estimate label width proportional to `name.count × fontSize`, or use a wider conservative default.

### 9. Redundant DispatchQueue.main.async inside a .main callback

**File:** `MotionManager.swift`

```swift
motionManager.startDeviceMotionUpdates(to: .main) { ... 
    DispatchQueue.main.async { self?.heading = heading }  // already on main
}
```

Remove the inner `DispatchQueue.main.async`.

---

## 🔵 Suggestions

### 10. Zoom display label mixes meters and km with same "m" suffix

```swift
"Zoom: %.2f (%.0f - %.0fm)"  // min is meters, max is divided by 1000 but still labeled "m"
```

Use `"%.0fm - %.1fkm"` or make units explicit.

### 11. No overlay feedback when all categories disabled

If the user disables all categories, the AR view is silently empty. A brief overlay message ("No categories enabled — check Settings") would help.

### 12. `maxDisplayedLabels` is a file-scoped global

Should be `static let` on `AROverlayView`.

### 13. MKLocalSearch radius uses degrees — inaccurate at high latitudes

```swift
MKCoordinateSpan(latitudeDelta: searchRadiusMiles / 69.0, longitudeDelta: searchRadiusMiles / 69.0)
```

At 60°N, 1° longitude ≈ 35 miles. Use `MKCoordinateRegion(center:latitudinalMeters:longitudinalMeters:)` instead.

### 14. `campground` is the only member of `sportsAndRecreation`

It belongs better in `natureAndOutdoors`. Either move it or add more recreation categories to the group.

---

## What's Done Well

- **ARLabelPositioner**: Mathematically solid. Bearing wrap-around at 0/360 handled correctly. FOV fade zones are a nice touch.
- **POIScorer**: Clean multi-factor scoring with sensible weights and a smooth parabolic distance curve.
- **SettingsManager**: Good persistence pattern. Group-level toggles are the right UX.
- **ZoomGestureManager**: Incremental delta calculation is correct — avoids the cumulative scale mistake.
- **Test coverage**: Genuine tests, not just instantiation checks. The geometry and scoring tests are solid.
- **Privacy**: Uses only Apple Maps (no external APIs). Camera and location gated by permission flows. No hardcoded secrets.
