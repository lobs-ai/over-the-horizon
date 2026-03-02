# Over the Horizon — Full App Review

**Reviewer:** Reviewer Agent  
**Date:** 2026-03-02  
**Scope:** Full code quality, spec compliance, performance, edge cases, UX, privacy

---

## Summary

The architecture is solid and test coverage is unusually thorough for a mobile app. The main blocking issues are a fundamental compass heading bug (AR labels will point wrong directions on every launch), tests that won't compile due to API drift, and a zoom display unit mislabel. Everything else is polish.

---

## 🔴 Critical

### 1. MotionManager heading is device-relative, not compass-bearing

**File:** `MotionManager.swift` — `calculateHeading(from:)`

```swift
let heading = (yaw * 180.0 / Double.pi) + 180.0
```

CMAttitude yaw with `.xArbitraryZVertical` reference frame is relative to whatever direction the device was pointing when `startDeviceMotionUpdates` was called — it does **not** map to compass North. On every launch the yaw origin is random. AR labels will point at wrong bearings every launch.

**Fix:** Use `CLLocationManager.startUpdatingHeading()` and `locationManager(_:didUpdateHeading:)` for a true magnetic heading. The `trueHeading` or `magneticHeading` property of `CLHeading` is what's needed here.

---

### 2. AROverlayView tests won't compile — missing required init parameters

**File:** `OverTheHorizonTests.swift` — `AROverlayViewTests`, `ARIntegrationTests`, `MaxDisplayLimitTests`

```swift
// Missing zoomGestureManager: ZoomGestureManager()
let view = AROverlayView(pois: [poi], heading: 0.0)

// Missing adjustedPosition and zIndex
let view = POILabelView(poi: poi, heading: 0.0, positioner: positioner)
```

The test target likely fails to build entirely, meaning all tests are silently broken.

**Fix:** Add `zoomGestureManager: ZoomGestureManager()` to AROverlayView calls; add `adjustedPosition: CGPoint(x: 195, y: 422), zIndex: 0` to POILabelView calls.

---

## 🟡 Important

### 3. ContentView double-initializes all StateObjects

**File:** `ContentView.swift` — `init()`

Properties have both inline initializers AND are re-assigned in `init()`. Two `LocationManager` instances are created per view construction; the first is discarded. The only reason for a custom init is the `locationManager → poiSearchManager` dependency — the rest should just use inline init.

**Fix:** Remove the inline initializers for `cameraManager`, `motionManager`, `zoomGestureManager`, `settingsManager`. Keep custom `init()` only for the wiring that needs it.

---

### 4. Zoom status label has mixed units bug

**File:** `ContentView.swift` ~line 72

```swift
Text(String(format: "Zoom: %.2f (%.0f - %.0fm)", 
            zoomGestureManager.zoomLevel,
            zoomGestureManager.minDistance,
            zoomGestureManager.maxDistance / 1000))  // divided by 1000 but the "m" suffix still applies
```

`minDistance` is shown in meters, `maxDistance` is divided by 1000 (km) but still labeled "m". At default zoom shows "100 - 50m" instead of "100m - 50km".

**Fix:** `"Zoom: %.2fx  %.0fm – %.1fkm"` with both min and max values labeled correctly.

---

### 5. Timer scheduling may silently fail if init is off main thread

**File:** `POISearchManager.swift` — `setupPeriodicSearch()`

`Timer.scheduledTimer` adds to the current run loop. SwiftUI may construct `ContentView` (and thus `POISearchManager`) off the main thread; if so, the timer never fires.

**Fix:** Create the timer unscheduled, then `RunLoop.main.add(searchTimer!, forMode: .common)`.

---

### 6. OverlapResolver uses fixed 60×24pt bounds regardless of text length

**File:** `OverlapResolver.swift`

```swift
private let minLabelWidth: CGFloat = 60.0
private let minLabelHeight: CGFloat = 24.0
```

Long names ("Philadelphia Museum of Art") will visually overlap because the collision box is far too small. This makes the resolver mostly ineffective in dense areas.

**Fix:** Estimate width from `fontSize * charCount * ~0.55 + padding`. Pass font size into `resolveOverlaps` or calculate it there.

---

### 7. `clamp` in POIScorer uses parameter names that shadow stdlib

**File:** `POIScorer.swift`

```swift
private static func clamp(_ value: Double, min: Double, max: Double) -> Double {
    return max(min, min(value, max))  // 'max' and 'min' are local Doubles, not stdlib functions
}
```

Swift resolves this because calling a Double as a function fails type-checking, but it's fragile and confusing. Same for the CGFloat overload.

**Fix:** Rename params to `lo`/`hi` or use `Swift.max`/`Swift.min` explicitly.

---

## 🔵 Suggestions

### 8. No UI when permissions are denied

Denied camera or location shows a black screen with no explanation. Add a `.alert` or overlay guiding the user to Settings.

### 9. POI deduplication missing

Multiple category searches can return the same physical location. No coordinate-proximity dedup exists before sorting. Dense areas will show duplicates in the list and overlay.

### 10. `UIScreen.main.bounds` deprecated in iOS 16

**File:** `CameraPreviewView.swift` — use `UIView(frame: .zero)` instead.

### 11. golfCourse group inconsistency

`golfCourse` switch returns `.entertainmentAndAttractions` but conceptually belongs in sports/recreation. Minor — pick one and be consistent.

### 12. Info.plist XML comments

Some tooling rejects XML comments in plists. Consider removing them.

---

## What's Done Well

- Bearing normalization handles the 0°/360° wrap-around correctly throughout.
- `POIScorer` multi-factor weighting (category + distance + prominence + directional centrality) is thoughtful — better than naive distance sort.
- Test suite is extensive — 400+ cases covering zoom, overlap resolution, scoring, settings persistence.
- Privacy is clean: only the three required permissions, no external data calls, all POI data from Apple Maps on-device.
- `@MainActor` on `ZoomGestureManager` is correct.
- `SettingsManager` persistence and group-level toggles work well.

---

## Priority Handoffs

| Priority | Issue | File |
|----------|-------|------|
| 🔴 1 | Heading from CoreLocation not CMMotion | MotionManager.swift |
| 🔴 2 | Fix non-compiling AROverlayView/POILabelView tests | OverTheHorizonTests.swift |
| 🟡 3 | Clean up ContentView double init | ContentView.swift |
| 🟡 4 | Fix zoom label unit mislabel | ContentView.swift |
| 🟡 5 | Fix Timer RunLoop.main scheduling | POISearchManager.swift |
