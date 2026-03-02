# Over the Horizon — Full App Review

**Reviewed:** 2026-03-02  
**Scope:** Spec compliance, Swift quality, performance, edge cases, UX, privacy

---

## Overall Assessment

The architecture is clean and well-structured. Component boundaries are sensible, test coverage is extensive, and the code reads clearly. That said, there are several issues ranging from critical to important — the most serious being the heading source, which breaks the core AR feature.

---

## 🔴 Critical Issues

### 1. Heading source is wrong — CMMotion yaw ≠ compass heading

**File:** `MotionManager.swift` — `calculateHeading(from:)`

The app derives heading from `CMAttitude.yaw`. This is a **device-relative angle with no reference to magnetic north**. The yaw axis drifts and starts from an arbitrary orientation — it does not indicate which direction is north.

For an AR overlay that positions labels by compass bearing ("Museum is 45° NE"), heading **must** come from `CLLocationManager.startUpdatingHeading()`, which returns `CLHeading` with true magnetic bearing.

**Impact:** Every POI label is currently positioned relative to an arbitrary initial orientation, not the real compass direction. The core AR feature is broken.

**Fix:** In `LocationManager`, add `locationManager.startUpdatingHeading()` and expose `@Published var heading: CLLocationDegrees?`. Update `ContentView` and `AROverlayView` to consume it. Remove heading calculation from `MotionManager`.

---

### 2. `POIScorer.clamp` — parameter names shadow stdlib, likely compile error

**File:** `POIScorer.swift`

```swift
private static func clamp(_ value: Double, min: Double, max: Double) -> Double {
    return max(min, min(value, max))  // ERROR: calling Double as function
}
```

Parameters named `min`/`max` shadow Swift's global `min()`/`max()` functions. `max(min, ...)` attempts to call a `Double` value as a function — this is a compile error. Same issue in the `CGFloat` overload.

**Fix:** Rename parameters to `lowerBound`/`upperBound`, or call `Swift.max`/`Swift.min` explicitly.

---

### 3. ContentView init creates duplicate StateObjects

**File:** `ContentView.swift`

The struct declares `@StateObject private var locationManager = LocationManager()` at the property level, then overrides it in `init()`. The `locationMgr` used to build `POISearchManager` may not be the same instance stored in `@StateObject`.

```swift
// Declared at property level: creates one LocationManager
@StateObject private var locationManager = LocationManager()

init() {
    let locationMgr = LocationManager()  // creates another
    _locationManager = StateObject(wrappedValue: locationMgr)  // replaces, but...
    // the locationMgr here IS correct, but the property-level init runs first
}
```

Also, `@StateObject private var cameraManager = CameraManager()` is overridden in init — the first allocation is wasted.

**Fix:** Remove the `= ManagerType()` initializers from property declarations (they're overridden anyway). Keep all initialization in `init()` only. The `locationMgr` assignment in init looks correct — just remove the duplicate property-level initializers.

---

### 4. Test compilation errors — AROverlayView missing required parameter

**File:** `OverTheHorizonTests.swift` — `AROverlayViewTests`, `ARIntegrationTests`, `MaxDisplayLimitTests`

```swift
let view = AROverlayView(pois: [poi], heading: 0.0)  // missing: zoomGestureManager
```

`AROverlayView` requires `zoomGestureManager: ZoomGestureManager`. These tests won't compile.

**Fix:** Add a `ZoomGestureManager()` argument to all these test call sites, or add a convenience init with a default `ZoomGestureManager()`.

---

## 🟡 Important Issues

### 5. CMMotion missing north-reference frame

**File:** `MotionManager.swift`

```swift
motionManager.startDeviceMotionUpdates(to: .main) { ... }
```

Uses default frame `.xArbitraryZVertical` — no magnetic north reference. If CMMotion heading is ever used, change to:
```swift
motionManager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical, to: .main) { ... }
```

---

### 6. Misleading dead variable in MotionManager

**File:** `MotionManager.swift`

```swift
private let locationManager = CoreMotion.CMHeadingFilterValueDefault
```

Stores a Float constant with a name implying it's a location manager. Unused. Remove it.

---

### 7. Double initialization fires two searches at startup

**File:** `POISearchManager.swift`, `ContentView.swift`

`POISearchManager.init()` calls `setupPeriodicSearch()` → fires `Task { await searchPOIs() }`.  
Then `ContentView.onAppear` calls `poiSearchManager.startPeriodicSearch()` → calls `setupPeriodicSearch()` again, cancels the first timer, fires another search.

Two concurrent searches run at startup. No cancellation mechanism exists, so both attempt to write `self.pois`.

**Fix:** Either remove the `setupPeriodicSearch()` call from `init()` and rely on `startPeriodicSearch()` from the view, or guard against duplicate starts. Add `Task` cancellation tokens so stale searches are aborted when a new one begins.

---

### 8. OverlapResolver uses fixed label dimensions

**File:** `OverlapResolver.swift`

```swift
private let minLabelWidth: CGFloat = 60.0
private let minLabelHeight: CGFloat = 24.0
```

Actual label size depends on POI name length and font size (10–24pt by distance, then multiplied by zoom). "Philadelphia Museum of Art" at 500m is much larger than "Zoo" at 40km. Fixed dimensions mean overlap detection is inaccurate — labels will visually overlap despite the resolver "clearing" them, or get unnecessarily offset.

**Fix:** Pass estimated dimensions into `resolveOverlaps` based on name length × font size, or increase conservative defaults substantially.

---

### 9. screenSize starts at .zero — label flash on startup

**File:** `AROverlayView.swift`

```swift
@State private var screenSize: CGSize = .zero
```

On first render, `ARLabelPositioner` gets `screenWidth: 0, screenHeight: 0`. All labels position at `(0, 0)` for one frame before `onAppear` fires. This creates a visible flash or jump.

**Fix:** Use `GeometryReader` in a `.background()` modifier that captures size synchronously before the overlay content renders, or use `UIScreen.main.bounds` as the initial value.

---

### 10. Search radius setting has no UI

**File:** `POISearchManager.swift`, `SettingsView.swift`

`searchRadiusMiles` is a published, validated property (1–5 miles) but there's no UI to change it. The Settings modal only shows category filters. This validated property implies the feature was planned and left incomplete — either add the slider or remove the dead published property.

---

### 11. Inconsistent category grouping — campground is alone in "Sports and Recreation"

**File:** `LocationCategory.swift`

`campground` is the only member of `sportsAndRecreation`. Meanwhile `golfCourse` and `recreationFacility` are in `entertainmentAndAttractions`. `campground` more naturally belongs in `natureAndOutdoors` alongside `trailhead`. The single-item group looks awkward in the Settings modal.

---

### 12. `NSLocationAlwaysAndWhenInUseUsageDescription` present but always-permission never requested

**File:** `Info.plist`, `LocationManager.swift`

The app only calls `requestWhenInUseAuthorization()` but the plist includes an "always" description. This is misleading and could flag during App Store review. Remove the always description, or justify it.

---

## 🔵 Suggestions

### 13. Main-thread double dispatch in MotionManager

```swift
// Callback already runs on .main:
motionManager.startDeviceMotionUpdates(to: .main) { ... }
// Inside callback:
DispatchQueue.main.async { self?.heading = heading }  // redundant
```

Remove the inner `DispatchQueue.main.async`. Already on main.

### 14. Label truncation at 1 line makes same-category POIs indistinguishable

When "Museum of Art" and "Museum of Science" are both in FOV, both become "Museum of..." Consider 2-line labels for close POIs or showing a category icon.

### 15. Zoom HUD format inconsistency

```swift
Text(String(format: "Zoom: %.2f (%.0f - %.0fm)", zoomGestureManager.zoomLevel,
            zoomGestureManager.minDistance, zoomGestureManager.maxDistance / 1000))
```

Shows minDistance in meters but maxDistance÷1000 with a trailing "m" — at zoom-out shows "300 - 100m" (meaning 300m to 100km, but both read as "m"). Format consistently: both km, or auto-format.

### 16. POI list shows bearing as raw degrees — prefer cardinal direction

"45°" is less intuitive than "NE (45°)". A quick `bearing → cardinal` mapping improves UX.

---

## Test Coverage Assessment

Tests are **unusually thorough** for a feature app. `ARLabelPositioner`, `ZoomGestureManager`, `POIScorer`, `OverlapResolver`, and `SettingsManager` all have solid unit tests with edge cases. Bearing/distance math is well tested.

**Gaps:**
- `MotionManager` heading calculation untested (and broken — see #1)
- `POISearchManager` movement threshold logic is untestable without mocking `LocationManager`
- `AROverlayViewTests` won't compile (see #4)

---

## Summary Table

| # | Severity | Issue |
|---|----------|-------|
| 1 | 🔴 | CMMotion yaw used for heading — not north-referenced |
| 2 | 🔴 | `POIScorer.clamp` shadows stdlib min/max — compile error |
| 3 | 🔴 | ContentView init duplicate StateObject instances |
| 4 | 🔴 | Test compilation errors — AROverlayView missing parameter |
| 5 | 🟡 | CMMotion missing north-reference frame |
| 6 | 🟡 | Dead misleading variable in MotionManager |
| 7 | 🟡 | Double search at startup, no Task cancellation |
| 8 | 🟡 | OverlapResolver uses fixed label dimensions |
| 9 | 🟡 | screenSize = .zero causes label flash |
| 10 | 🟡 | Search radius has no UI (dead feature) |
| 11 | 🟡 | Campground alone in Sports & Recreation group |
| 12 | 🟡 | Always-location description present but unused |
| 13 | 🔵 | Double main-thread dispatch in MotionManager |
| 14 | 🔵 | 1-line label truncation hurts disambiguation |
| 15 | 🔵 | Zoom HUD unit inconsistency |
| 16 | 🔵 | Cardinal directions in POI list |
