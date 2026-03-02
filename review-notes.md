# Over the Horizon — Full App Review

**Reviewer:** Reviewer Agent  
**Date:** 2026-03-02  
**Scope:** Full codebase review — correctness, Swift practices, performance, edge cases, UX, privacy, tests

---

## Summary

Clean architecture and solid separation of concerns. Good POI scoring logic, bearing math, and business logic test coverage. However there are **two critical bugs** that break core functionality, plus several important issues.

---

## 🔴 Critical

### 1. Heading is not a compass heading — AR labels will point in wrong directions

**File:** `MotionManager.swift` — `calculateHeading(from:)`

```swift
let heading = (yaw * 180.0 / Double.pi) + 180.0
```

`CMAttitude.yaw` is rotation relative to an **arbitrary reference frame set at motion start** — NOT a compass heading. On every cold start, "north" is in a random direction. The AR overlay will render labels consistently pointing the wrong way.

**Fix:** Use `CLLocationManager.startUpdatingHeading()` for compass-based heading, or use `CMMotionManager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical)` which anchors yaw to magnetic north. The `CMAttitudeReferenceFrame.xMagneticNorthZVertical` reference frame is the correct choice for AR heading.

This is the most important bug. Nothing else renders correctly without it.

---

### 2. AROverlayView and POILabelView tests missing required parameters — won't compile

**File:** `OverTheHorizonTests.swift` — `AROverlayViewTests`

```swift
// Missing zoomGestureManager: ZoomGestureManager
let view = AROverlayView(pois: [poi], heading: 0.0)

// Missing adjustedPosition: CGPoint, zIndex: Int
let view = POILabelView(poi: poi, heading: 0.0, positioner: positioner)
```

These tests would not compile, silently eliminating AR overlay test coverage. Fix:
```swift
let view = AROverlayView(pois: [poi], heading: 0.0, zoomGestureManager: ZoomGestureManager())
let view = POILabelView(poi: poi, heading: 0.0, positioner: positioner,
                        adjustedPosition: CGPoint(x: 195, y: 422), zIndex: 0)
```

---

## 🟡 Important

### 3. MKLocalSearch ignores MKPointOfInterestCategory — unreliable results

**File:** `POISearchManager.swift` — `searchCategory()`

The code defines a full `mkCategory` mapping in `LocationCategory.swift` but never uses it. Instead it queries by free text (`naturalLanguageQuery = category.rawValue`). Queries like "viewpoint", "ferry terminal", "historic site" return inconsistent results. The `pointOfInterestFilter` API exists specifically for this:

```swift
if #available(iOS 14.0, *) {
    searchRequest.pointOfInterestFilter = MKPointOfInterestFilter(including: [category.mkCategory])
}
```

Categories like `ferryTerminal` (mapped to `.park`) will return wrong results either way — the mkCategory mappings need an audit too.

---

### 4. ContentView double-initializes @StateObject — leaks instances

**File:** `ContentView.swift`

```swift
@StateObject private var locationManager = LocationManager()  // Creates instance #1

init() {
    let locationMgr = LocationManager()                         // Creates instance #2
    _locationManager = StateObject(wrappedValue: locationMgr)  // Discards instance #1
    ...
}
```

All five `@StateObject` properties have this pattern. Remove the default initializers on the property declarations when providing a custom `init()`.

---

### 5. setupPeriodicSearch() called twice on launch — 48 MapKit requests fire immediately

**File:** `POISearchManager.swift`

`init()` calls `setupPeriodicSearch()` which starts a timer and fires an immediate `searchPOIs()`. Then `ContentView.onAppear` calls `startPeriodicSearch()` → `setupPeriodicSearch()` again, cancels the first timer, and fires another immediate `searchPOIs()`. Result: 24 MKLocalSearch requests × 2 = 48 search requests on every launch.

**Fix:** Remove `setupPeriodicSearch()` from `init()`. Let `startPeriodicSearch()` handle setup entirely. Fire a single initial search from `onAppear` if needed.

---

### 6. NSLocationAlwaysAndWhenInUseUsageDescription present but app never requests Always

**File:** `Info.plist`

`LocationManager` only calls `requestWhenInUseAuthorization()` but the plist declares `NSLocationAlwaysAndWhenInUseUsageDescription`. App Store review may flag this. Remove the Always key.

---

### 7. Overlap resolver uses fixed 60pt label width — misses real overlaps

**File:** `OverlapResolver.swift`

```swift
private let minLabelWidth: CGFloat = 60.0
```

Long names ("Philadelphia Museum of Art") render at 200+ points but overlap detection treats all labels as 60×24pt. Two wide labels side-by-side won't be detected as overlapping. Increase the estimate (e.g., 150pt) or pass actual rendered size.

---

## 🔵 Suggestions

### 8. Redundant main queue dispatch in MotionManager

`startDeviceMotionUpdates(to: .main)` already runs callbacks on main. The inner `DispatchQueue.main.async { self?.heading = heading }` is redundant. Remove the wrapper.

### 9. Confusing unused constant in MotionManager

```swift
private let locationManager = CoreMotion.CMHeadingFilterValueDefault
```

Named `locationManager` but stores a Float constant. Never used. Delete it.

### 10. Zoom display format bug

```swift
Text(String(format: "Zoom: %.2f (%.0f - %.0fm)",
    zoomGestureManager.zoomLevel,
    zoomGestureManager.minDistance,
    zoomGestureManager.maxDistance / 1000))  // divides to km but label says "m"
```

At default zoom this shows "100 - 50m" when it should be "100m - 50km". Fix the unit label.

### 11. Settings dismissal triggers search even if nothing changed

`SettingsView.onDisappear` fires a full re-search every dismiss regardless of whether categories changed. Track a `didChange` flag in `SettingsManager` and only search when needed.

### 12. POIScorer.clamp shadows stdlib min/max — correctness trap

```swift
private static func clamp(_ value: Double, min: Double, max: Double) -> Double {
    return max(min, min(value, max))  // parameter `max` shadows stdlib max()
}
```

Works coincidentally today but is a readability/maintenance hazard. Rename parameters to `minVal`/`maxVal` or use explicit `Swift.max`/`Swift.min`.

---

## What's Done Well

- **Architecture**: Clean SRP separation across LocationManager, MotionManager, POISearchManager, ARLabelPositioner, OverlapResolver. Independently testable.
- **POI Scoring**: Weighted multi-factor scoring (category, distance, prominence, directional centrality) is well-designed. Math is correct.
- **Bearing normalization**: `normalizeBearingDifference` is correctly implemented and consistently used throughout.
- **Zoom gesture**: The incremental delta calculation (`scaleDelta = value / lastMagnificationScale`) correctly handles cumulative `MagnificationGesture` values. Good implementation.
- **Privacy**: No external network calls, no analytics, permissions properly declared (minus the Always location nit above).
- **Business logic test coverage**: ARLabelPositioner, ZoomGestureManager, POIScorer, OverlapResolver, SettingsManager all have thorough tests with good edge cases.

---

## Priority Fix Order

1. Fix heading calculation (use magnetic north reference frame) — **app is non-functional without this**
2. Fix AROverlayView/POILabelView tests (compilation failure, no AR test coverage)
3. Use MKPointOfInterestCategory in search (reliability)
4. Fix double-init and double-search-on-launch (performance/battery)
5. Remove unnecessary Always location key from plist (App Store risk)
6. Improve overlap resolver label width estimate (UX in dense areas)
