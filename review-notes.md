# Code Review: Over the Horizon

**Reviewer:** Reviewer Agent  
**Date:** 2026-03-02  
**Scope:** Full app review — code quality, performance, spec compliance

---

## Summary

The overall architecture is sound and well-structured for a Swift AR overlay app. Clean separation of concerns (CameraManager, LocationManager, MotionManager, etc.), good test coverage breadth, and thoughtful UI design. There are several correctness bugs though — the most serious being a **broken heading implementation** — plus performance and edge-case issues.

---

## 🔴 Critical

### 1. Heading computed incorrectly — AR labels will point wrong directions

**File:** `MotionManager.swift` → `calculateHeading(from:)`

`CMAttitude.yaw` is NOT magnetic heading. It is rotation around Z relative to whatever reference frame the device motion started with (gravity-aligned, not north-aligned). The result is arbitrary and doesn't correspond to compass direction.

**Fix:** Use `.xMagneticNorthZVertical` reference frame when starting device motion:
```swift
motionManager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical, to: .main) { ... }
```
With that frame, yaw gives compass heading. Without it, the app is non-functional as an AR overlay.

---

### 2. Dead/misleading code in MotionManager

**File:** `MotionManager.swift`, line 15:
```swift
private let locationManager = CoreMotion.CMHeadingFilterValueDefault
```
`CMHeadingFilterValueDefault` is a `Double` (value 1.0), not a location manager. The name `locationManager` is completely misleading. Remove it.

---

## 🟡 Important

### 3. Double main-queue dispatch in MotionManager

`startDeviceMotionUpdates(to: .main)` already delivers on main, but the handler also does `DispatchQueue.main.async { self?.heading = heading }`. Double dispatch = extra latency. Assign heading directly.

### 4. setupPeriodicSearch called twice on startup

`POISearchManager.init` calls `setupPeriodicSearch()`. Then `ContentView.onAppear` calls `startPeriodicSearch()` which calls `setupPeriodicSearch()` again. Two async `searchPOIs()` tasks fire at startup.

### 5. AROverlayView starts with screenSize = .zero

All label position/visibility calculations on first render use a 0×0 screen. Labels won't appear until the next layout pass. Use `GeometryReader` synchronously in `body` rather than `onAppear`.

### 6. Overlap detector uses fixed 60×24pt label bounds

**File:** `OverlapResolver.swift`

Long POI names ("Philadelphia Museum of Art") render far wider than 60pt. The overlap resolver misses collisions, leading to visually overlapping labels. Use a more realistic estimate (120–180pt width) or compute from name length × font size.

### 7. OverlapResolver only tries 3 positions — too limited for 10 labels in a city

With `maxVerticalLevels = 3` (base, -60pt, +60pt), labels 4–10 in a dense area all get stacked. Increase levels or use a smarter placement strategy.

### 8. MKLocalSearch uses NL query instead of category filter

**File:** `POISearchManager.swift`

```swift
searchRequest.naturalLanguageQuery = category.rawValue
```

Uses strings like "historic site", "recreation facility" as NL queries. The `LocationCategory.mkCategory` property maps to `MKPointOfInterestCategory` but is never used in the search. Fix:
```swift
searchRequest.pointOfInterestFilter = MKLocalPointOfInterestFilter(including: [category.mkCategory])
```
This would give more reliable, precise results.

### 9. No user feedback when permissions are denied

Both `CameraManager` and `LocationManager` set `authorizationStatus = .denied` silently. The UI shows a blank camera view with no explanation. A permission-denied state with Settings redirect is missing.

### 10. POILocation.id creates duplicates on refresh

```swift
let id = UUID()
```

Every `searchPOIs()` run creates new `POILocation` instances with new UUIDs. SwiftUI sees all labels as "new" on every 30s refresh, forcing full remove+add animations instead of smooth updates. Use a stable ID based on name + coordinate hash.

### 11. Info.plist — landscape-only for a camera AR app

The app is portrait-excluded but camera AR apps are almost universally portrait-first. The label positioning code doesn't account for this. If intentional, add a comment.

### 12. searchCategory mixes async/await with DispatchQueue.main.async

Inside an `async` function, use `await MainActor.run { ... }` not `DispatchQueue.main.async { ... }`. Mixing GCD and Swift concurrency risks data races under strict concurrency checking.

---

## 🔵 Suggestions

### 13. Battery: no accuracy/distance filter on CLLocationManager

`startUpdatingLocation()` with defaults hammers GPS. Set:
```swift
locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
locationManager.distanceFilter = 50.0
```

### 14. displayedPOIs and resolvedLabels computed on every render

These run full filter/score/sort/overlap-resolve pipelines as computed properties, potentially at 60fps. Cache results; update only when inputs (pois, heading, zoom) change.

### 15. Settings always triggers re-search on dismiss even without changes

`onDisappear` in `.sheet(isPresented: $showSettings)` always fires `searchPOIs()`. Track whether settings actually changed.

### 16. Zoom display bug — inconsistent units

```swift
Text(String(format: "Zoom: %.2f (%.0f - %.0fm)", 
    zoomGestureManager.zoomLevel,
    zoomGestureManager.minDistance,
    zoomGestureManager.maxDistance / 1000))
```

At default zoom this shows "Zoom: 1.00 (100 - 50m)" — min in meters, max divided by 1000 but still labeled "m". Shows 50 not 50km. Fix the format string.

---

## What's Done Well

- **Good architectural separation**: Each concern has its own manager class, cleanly scoped.
- **Solid test breadth**: `ARLabelPositionerTests`, `POIScorerTests`, `ZoomGestureManagerTests` have real assertions, not just smoke tests.
- **Bearing math is correct**: `normalizeBearingDifference` and `calculateBearing` handle 0/360 wraparound properly, and it's tested.
- **Privacy info.plist is complete**: Camera, location, and motion usage descriptions all present.
- **OverlapResolver priority design**: Higher-scored POIs keep position, lower ones get nudged — right call.
- **Settings persistence**: Clean `UserDefaults` implementation with group-level toggle UX.

---

## Priority Fix Order

1. `MotionManager.swift` — heading reference frame (critical, app won't work)
2. `OverlapResolver.swift` — label bounds too small
3. `POISearchManager.swift` — double init, async/GCD mix, use category filter
4. `AROverlayView.swift` — screenSize zero on first frame, expensive computed props
5. `ContentView.swift` — permission denied UX, zoom display bug
6. `LocationManager.swift` — battery efficiency
