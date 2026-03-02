# Over the Horizon — Full App Review
**Date:** 2026-03-02  
**Reviewer:** Reviewer Agent  
**Scope:** Spec compliance, Swift best practices, performance, edge cases, UX polish, privacy

---

## Summary

Solid architecture overall — the separation of concerns across managers is clean and the test coverage is unusually broad for an AR app. However there are a handful of issues ranging from a broken heading sensor to compilation errors in tests that need to be fixed before this ships.

---

## 🔴 Critical Issues

### 1. Wrong Heading Source in MotionManager — AR Overlay Will Point Wrong Direction
**File:** `MotionManager.swift`, `calculateHeading(from:)`

`heading` is derived from CMAttitude's `.yaw`, which is the device's rotation relative to an **arbitrary reference frame** (typically its orientation at startup). It is not aligned to geographic north. The AR overlay uses this heading to determine which POIs appear on screen — if the heading is wrong, the entire overlay is wrong.

Fix: Use `CLLocationManager.startUpdatingHeading()` with the `locationManager(_:didUpdateHeading:)` delegate method, which returns a `trueHeading` calibrated to magnetic north. The `CLLocationManager` instance in `LocationManager.swift` already exists — extend it to publish heading alongside location.

### 2. Test Compilation Errors — AROverlayView and POILabelView Tests
**File:** `OverTheHorizonTests.swift` — `AROverlayViewTests`, `MaxDisplayLimitTests`

Multiple test cases call `AROverlayView(pois:heading:)` without the required `zoomGestureManager` parameter, e.g.:

    let view = AROverlayView(pois: [poi], heading: 0.0)

`AROverlayView` has `@ObservedObject var zoomGestureManager: ZoomGestureManager` as a required parameter — omitting it is a compile error.

Similarly, `POILabelView` tests omit `adjustedPosition` and `zIndex` which are required.

Fix: pass `zoomGestureManager: ZoomGestureManager()` and the missing positional params.

### 3. Initial POI Search Ignores Saved Category Settings
**File:** `POISearchManager.swift` → `setupPeriodicSearch()`, `ContentView.swift` → `onAppear`

`ContentView.onAppear` calls `poiSearchManager.startPeriodicSearch()` which internally calls `searchPOIs()` with no categories argument — defaulting to all 24 categories regardless of what the user saved in a prior session. Settings only take effect when the user opens and dismisses the Settings modal.

Fix: Pass `settingsManager.getEnabledCategories()` to `startPeriodicSearch` (add parameter) or have `POISearchManager` accept a settings reference.

---

## 🟡 Important Issues

### 4. MKLocalSearch Natural Language Queries Are Unreliable for Category Search
**File:** `POISearchManager.swift` → `searchCategory(_:from:)`

    searchRequest.naturalLanguageQuery = category.rawValue  // "landmark", "museum", etc.

`MKLocalSearch` with a natural language query is designed for text searches, not POI category lookups. Results are unpredictable. The codebase already has `LocationCategory.mkCategory` returning the correct `MKPointOfInterestCategory` — use it. Switch to `MKLocalPointsOfInterestRequest` with `MKPointOfInterestFilter`:

    let request = MKLocalPointsOfInterestRequest(coordinateRegion: region)
    request.pointOfInterestFilter = MKPointOfInterestFilter(including: [category.mkCategory])

This is correctness, not just performance — natural language search may return restaurants or other filtered-out categories.

### 5. Stale Bearing and Distance After User Moves
**File:** `POILocation.swift`, `POISearchManager.swift`

`bearing` and `distance` are computed once at search time and stored as constants. As the user walks, displayed angles and distances drift until the next 500m-threshold search. At 500m displacement, a POI's bearing can shift several degrees — enough to visibly misplace labels.

Fix: Recalculate bearing and distance from the user's live location in `AROverlayView` or `ARLabelPositioner`, rather than relying on stored values in `POILocation`.

### 6. AROverlayView — Labels Render at (0,0) on First Frame
**File:** `AROverlayView.swift`

    @State private var screenSize: CGSize = .zero

On the very first render, `positioner` uses `screenWidth: 0, screenHeight: 0`, so all label positions are `CGPoint(x: 0, y: 0)`. Labels will flash at the top-left corner before `onAppear` fires.

Fix: Guard rendering until `screenSize != .zero`, e.g. `if screenSize != .zero { ZStack { ForEach(...) } }`.

### 7. OverlapResolver — Fixed 60pt Label Width Misses Long Names
**File:** `OverlapResolver.swift`

    private let minLabelWidth: CGFloat = 60.0

POI names like "National Museum of Natural History" render far wider than 60pt, so the overlap detector misses collisions between side-by-side labels. Result: visually overlapping text on screen.

Fix: Estimate label width from `NSString.size(withAttributes:)` using the same font size, or pass actual rendered sizes from the view layer.

### 8. NSLocationAlwaysAndWhenInUseUsageDescription Not Needed
**File:** `Info.plist`

The app only calls `requestWhenInUseAuthorization()`. The `NSLocationAlwaysAndWhenInUseUsageDescription` key should be removed — it signals background location usage to App Store review when the app doesn't actually use it. Remove it.

### 9. Landscape-Only Orientation Is Unusual for AR Camera App
**File:** `Info.plist`

The app only supports landscape. Users typically hold phones in portrait when pointing at a horizon or building. Unless there's a strong product reason, add portrait support or at minimum document the rationale.

### 10. MotionManager — Misleading Unused Property
**File:** `MotionManager.swift`, line 16

    private let locationManager = CoreMotion.CMHeadingFilterValueDefault

This stores the value `0.0` (a constant) in a property named `locationManager`. It's never used. Remove it.

---

## 🔵 Suggestions

### 11. ContentView — Redundant StateObject Initialization
**File:** `ContentView.swift`

The struct declares both `@StateObject private var cameraManager = CameraManager()` at property level AND re-initializes it in `init()`. The top-level declarations create throwaway instances. Keep only one pattern.

### 12. CameraPreviewView — UIScreen.main.bounds Is Deprecated
**File:** `CameraPreviewView.swift`

`UIScreen.main` is deprecated in iOS 16+. The frame is overridden by the layout engine anyway. Use `UIView()` with no frame and let SwiftUI manage sizing.

### 13. POIScorer — clamp() Parameter Shadowing stdlib
**File:** `POIScorer.swift`

Parameter names `min` and `max` shadow `Swift.min()` and `Swift.max()`. This works but is fragile. Rename params to `lower`/`upper`.

### 14. Settings Trigger Unnecessary Re-search on Every Dismiss
**File:** `ContentView.swift` → `SettingsView.onDisappear`

Re-search fires even when no categories changed. Track a dirty flag in `SettingsManager` and only re-search when something actually changed.

### 15. Missing "No Heading" UX State in AR Overlay
When `motionManager.heading == nil` (simulator, cold start), `displayedPOIs` returns empty silently. Show a "Waiting for compass…" message so users understand why nothing appears.

---

## What's Working Well

- Clean separation of concerns — each manager is well-scoped and easy to follow.
- Overlap resolution algorithm is sensible and well-tested.
- Test breadth is genuinely good — bearing math, distance clamping, zoom invariants, settings persistence all covered.
- Incremental pinch delta approach (`lastMagnificationScale`) is the correct pattern for `MagnificationGesture`.
- Privacy is tight: no external network calls, only Apple Maps local search. Descriptions are accurate.
- `POIScorer` multi-factor scoring (category × distance × prominence × centrality) is a good approach.
- `ZoomGestureManager` bounds invariants (`minDistance < maxDistance` for all zoom levels) are solid.

---

## Priority Order for Fixes

1. Fix heading source (CMAttitude yaw → CLHeadingManagerDelegate) — the overlay doesn't work without this
2. Fix test compilation errors
3. Apply saved category settings on startup  
4. Switch to MKLocalPointsOfInterestRequest for reliable POI results
5. Fix first-frame zero screenSize flash
6. Remove `NSLocationAlwaysAndWhenInUseUsageDescription`
7. Live bearing recalculation
8. Label width estimation for overlap resolver
