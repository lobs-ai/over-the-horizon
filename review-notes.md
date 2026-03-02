# Over the Horizon — Full App Review
**Reviewed:** 2026-03-02  
**Reviewer:** reviewer-agent

---

## Summary

Solid foundation with good architecture and thorough test coverage. Found two critical bugs that will cause incorrect AR behavior and test compilation failures. Several important issues around sensor accuracy and stale data. Overall the code is clean and readable.

---

## 🔴 Critical Issues

### 1. Heading is Wrong — CMDeviceMotion without North Reference Frame
**File:** `MotionManager.swift`

`startDeviceMotionUpdates(to: .main)` defaults to `xArbitraryZVertical` reference frame. This means `attitude.yaw` is relative to the device's orientation *at startup*, not magnetic or true north. The heading it produces is meaningless for compass-based AR label positioning — labels will point in wrong directions.

**Fix:** Use `startDeviceMotionUpdates(using: .xMagneticNorthZVertical, to: .main)` or use `CLLocationManager.startUpdatingHeading()` which provides calibrated magnetic heading directly.

Also: `private let locationManager = CoreMotion.CMHeadingFilterValueDefault` is a misleadingly-named Double constant (0.0). Dead code that looks like a bug.

### 2. AROverlayView Tests Won't Compile
**File:** `OverTheHorizonTests.swift` — `AROverlayViewTests`, `MaxDisplayLimitTests`

Multiple tests call `AROverlayView(pois:, heading:)` omitting the required `zoomGestureManager:` parameter. Also `POILabelView` tests omit `adjustedPosition` and `zIndex`. These are compile errors — the test suite won't build.

---

## 🟡 Important Issues

### 3. POI Bearing/Distance Goes Stale Between Searches
`POILocation.bearing` and `.distance` are computed once at search time. Between 30-second periodic searches, as the user moves, the AR overlay uses outdated bearing values. At driving speed this is significantly wrong.

**Fix:** Store the POI's `CLLocation` and recompute bearing/distance dynamically from current user location each frame in `AROverlayView`.

### 4. Duplicate Search on Startup
`init(locationManager:)` calls `setupPeriodicSearch()` which immediately fires a search. Then `ContentView.onAppear` calls `startPeriodicSearch()` → another immediate search. Two searches fire on launch.

### 5. OverlapResolver Uses Fixed Label Bounds
Labels are assumed to be 60×24 points, but actual rendered labels vary greatly with distance-based font size and name length. Close POIs with large fonts will overlap in practice without being detected.

### 6. ContentView Creates Redundant Manager Instances
All six `@StateObject` properties are re-initialized in `init()`. Only `poiSearchManager` actually needs custom init (to receive `locationManager`). The others allocate twice unnecessarily.

### 7. No Permission Denied UI
When camera or location is denied, the UI silently shows nothing. No alert, no "go to Settings" prompt. Users won't know how to recover.

### 8. UIScreen.main.bounds Deprecated
**File:** `CameraPreviewView.swift` — deprecated in iOS 16+. Use GeometryReader or view bounds.

---

## 🔵 Suggestions

### 9. clamp() Parameter Names Shadow Swift Built-ins
**File:** `POIScorer.swift` — parameters named `min`/`max` shadow `Swift.min()`/`Swift.max()`. Works by accident. Rename to `lower`/`upper`.

### 10. OverlapResolver Recreated Every Render
`private var overlapResolver: OverlapResolver { OverlapResolver() }` allocates on every view update. Make it a constant.

### 11. campground Miscategorized
Maps to `sportsAndRecreation` alone. Likely should be `natureAndOutdoors`.

### 12. mkCategory Not Used
Tested but never called in production code. `POISearchManager` uses `naturalLanguageQuery` instead. Remove or use it.

### 13. Debug HUD in Production UI
Raw lat/lon and heading display are debug-grade and should be gated by a debug flag.

---

## What's Done Well

- **ARLabelPositioner**: Pure struct, testable, clean FOV edge fade math. Well done.
- **Test coverage**: Extensive — nearly every class has tests with edge cases and integration tests.
- **POIScorer**: Scoring weights are well-reasoned and the directional centrality cosine curve is a nice touch.
- **ZoomGestureManager**: Correctly handles incremental scale delta problem and is comprehensively tested.
- **Privacy**: No external API calls, only Apple Maps. Only required permissions requested. ✅

---

## Priority Fix Order

1. Fix MotionManager reference frame (makes AR functionally broken)
2. Fix test compile errors (CI will fail)
3. Fix stale bearing/distance between searches
4. Add permission denied UI
5. Fix duplicate startup search
