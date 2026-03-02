# Code Review — Over the Horizon
**Reviewed:** 2026-03-02  
**Scope:** Full app — spec compliance, Swift practices, performance, edge cases, UX, privacy

---

## Summary

Solid foundation. The architecture is clean: `CameraManager`, `LocationManager`, `MotionManager`, `POISearchManager`, `ZoomGestureManager`, `SettingsManager`, and the AR overlay stack are all well-separated. Test coverage is broad, but several tests won't compile and there is one critical correctness bug in heading calculation that will make the app non-functional as an AR compass tool.

---

## 🔴 Critical

### 1. Heading calculation is wrong — app will never point at real locations

**File:** `MotionManager.swift` — `calculateHeading(from:)`

`CMAttitude.yaw` is measured relative to an arbitrary reference frame, not magnetic north. The conversion `(yaw * 180 / π) + 180` produces a device-relative angle, not a compass bearing. AR labels will be positioned in completely wrong directions.

**Fix:** Use `CLLocationManager.startUpdatingHeading()` and read `CLHeading.magneticHeading`. Or use `CMMotionManager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical)` and reference that frame. The existing heading math should be replaced entirely.

`MotionManager` also has a dead line: `private let locationManager = CoreMotion.CMHeadingFilterValueDefault` — this is just a Double constant, not a location manager, and it's unused.

---

### 2. Test suite has compilation errors

**File:** `OverTheHorizonTests.swift`

`AROverlayView` requires three arguments (`pois:`, `heading:`, `zoomGestureManager:`) but multiple tests omit `zoomGestureManager`:
```swift
let view = AROverlayView(pois: [poi], heading: 0.0)  // DOES NOT COMPILE
```
All `AROverlayView` tests and `MaxDisplayLimitTests` fail to compile.

`POILabelView` tests also omit `adjustedPosition:` and `zIndex:` — won't compile either.

---

## 🟡 Important

### 3. ContentView double-initializes all @StateObjects

**File:** `ContentView.swift`

Property declarations have default initializers (`= CameraManager()`, etc.) AND `init()` overwrites them all. The defaults create instances that are immediately discarded. Replace property declarations with type-only annotations:
```swift
@StateObject private var cameraManager: CameraManager
@StateObject private var locationManager: LocationManager
// etc.
```

### 4. Duplicate initial search on appear

`POISearchManager.init()` calls `setupPeriodicSearch()` (starts timer + fires search). Then `ContentView.onAppear` calls `startPeriodicSearch()` which calls `setupPeriodicSearch()` again — second search fires immediately. Remove the `setupPeriodicSearch()` call from `init()`.

### 5. Search radius has no UI

`POISearchManager.searchRadiusMiles` (1–5 miles) has clamping and tests but zero UI surface in `SettingsView`. Missing feature.

### 6. Unit label bug in zoom HUD

```swift
Text(String(format: "Zoom: %.2f (%.0f - %.0fm)", 
    zoomGestureManager.zoomLevel,
    zoomGestureManager.minDistance,
    zoomGestureManager.maxDistance / 1000))  // km, but says "m"
```
Also `minDistance` is shown unscaled in meters while `maxDistance` is divided by 1000 (km). Format string should be `"Zoom: %.2f (%.0fm - %.0fkm)"` with appropriate scaling.

### 7. Multi-category search errors overwrite each other

In `searchCategory(_:from:)`, each failing category overwrites `errorMessage`. Only the last error is visible to the user.

### 8. `campground` misclassified in Sports & Recreation

Fits better under `natureAndOutdoors` than `sportsAndRecreation`.

---

## 🔵 Suggestions

- **POILabelView** duplicates the FOV/distance visibility check that `AROverlayView.displayedPOIs` already performed. Remove it.
- **OverlapResolver** maxVerticalLevels=3 will fail silently with 10 dense labels. Consider more levels or horizontal jitter fallback.
- **POIScorer.clamp** — parameter names `min`/`max` shadow stdlib global functions. Rename to `lower`/`upper`.
- **Positioner/resolver as computed properties** — recreated every SwiftUI render. Fine for now, worth a `let` or caching if they grow.
- **Settings close triggers search unconditionally** — even if nothing changed. Diff enabled categories before/after to skip redundant searches.
- **Info.plist** — verify `NSCameraUsageDescription`, `NSLocationWhenInUseUsageDescription`, `NSMotionUsageDescription` are present and descriptive.

---

## What's Good

- Clean separation of concerns across all managers
- `ARLabelPositioner` is a pure, well-tested struct — easy to reason about
- `POIScorer` deterministic scoring with clear factor weights
- Zoom gesture incremental delta logic is correct (avoids cumulative scale trap)
- Privacy: all data is local, no external APIs, no PII
- Test coverage breadth is strong where it compiles
