# Over the Horizon — Full App Review

**Reviewer:** Agent (Reviewer)  
**Date:** 2026-03-02  
**Scope:** Full app review — spec compliance, Swift best practices, performance, edge cases, UX, privacy

---

## Summary

The app is well-structured with a clear separation of concerns. Core logic (positioning, scoring, overlap resolution) is solid and well-tested. Several important bugs exist, with one heading calculation issue that would cause the AR overlay to be non-functional in the real world. A few API misuses need fixing before shipping.

---

## 🔴 Critical Issues

### 1. MotionManager heading is NOT compass-bearing — AR labels will point wrong direction

**File:** `MotionManager.swift`, `calculateHeading(from:)`

`CMAttitude.yaw` is relative to the device's **arbitrary startup orientation**, not magnetic north. Turning the device will update `yaw`, but the zero-point is wherever the phone was pointing when the app launched. In practice, the AR labels will appear in totally wrong directions unless the user happens to launch while pointing north.

**Fix:** Use `CLLocationManager.startUpdatingHeading()` (already has location permission) or initialize CMMotionManager with `startDeviceMotionUpdates(using: .xMagneticNorthZVertical)` to anchor yaw to magnetic north.

Also: `private let locationManager = CoreMotion.CMHeadingFilterValueDefault` is a dead variable storing a `Float` constant under a misleading name. Remove it.

---

### 2. ContentView.init() creates double instances of every StateObject

**File:** `ContentView.swift`, `init()`

Every @StateObject has both a property-declaration initializer AND is re-initialized in `init()`. Instance #1 is thrown away. For CameraManager this wastes a camera session; for POISearchManager this fires a discarded network search burst.

**Fix:** Remove default initializers from property declarations when overriding in init():
```swift
@StateObject private var cameraManager: CameraManager
@StateObject private var locationManager: LocationManager
```

---

## 🟡 Important Issues

### 3. Double search fires on startup

**File:** `POISearchManager.swift`

`init()` calls `setupPeriodicSearch()` (fires immediate search + starts timer), then `ContentView.onAppear` calls `startPeriodicSearch()` which calls `setupPeriodicSearch()` again (fires ANOTHER immediate search). 48 simultaneous MKLocalSearch requests at launch.

**Fix:** Remove `setupPeriodicSearch()` call from `init()`.

---

### 4. Test file won't compile — AROverlayView/POILabelView init signature mismatches

**File:** `OverTheHorizonTests.swift`

Tests create `AROverlayView(pois: [poi], heading: 0.0)` missing required `zoomGestureManager:` parameter. `POILabelView` tests missing `adjustedPosition:` and `zIndex:` params.

---

### 5. MKLocalSearch uses natural language instead of POI category filters

**File:** `POISearchManager.swift`

`naturalLanguageQuery = category.rawValue` ("landmark", "museum") returns inconsistent results. `LocationCategory.mkCategory` is defined but never used.

**Fix:** Use `MKLocalSearch.Request.pointOfInterestFilter` with `.including([category.mkCategory])`.

---

### 6. Overlap detection uses hardcoded 60pt label width

**File:** `OverlapResolver.swift`

Long POI names (e.g., "Philadelphia Museum of Art") are far wider than 60pt. Dense areas will still show visible overlaps.

---

### 7. SettingsManager loads state asynchronously from init

**File:** `SettingsManager.swift`

`loadEnabledCategories()` wraps the state assignment in `DispatchQueue.main.async`, leaving `enabledCategories` empty until the next run loop. Synchronous read right after init returns empty list.

---

## 🔵 Suggestions

- `CameraPreviewView` uses deprecated `UIScreen.main.bounds` (iOS 16+ deprecated)
- Zoom direction is counterintuitive: pinch-out makes labels smaller (opposite of every map app)
- No heading smoothing — CMMotion at 10Hz without low-pass filter will cause label jitter
- POI distances/bearings go stale until 500m movement threshold — consider a softer refresh at 100m

---

## ✅ What's Done Well

- ARLabelPositioner: clean FOV math, correct 0/360° wraparound handling
- POIScorer: well-designed with clear weighting rationale, properly normalized
- OverlapResolver: priority-based algorithm is the right approach
- Test coverage is excellent in breadth across all major classes
- ZoomGestureManager: correct incremental delta handling for MagnificationGesture
- Privacy: no external data, permissions scoped correctly. Clean.

---

## Fix Priority

1. 🔴 Heading calculation (app non-functional without this)
2. 🔴 Double StateObject init in ContentView
3. 🟡 Double search on startup  
4. 🟡 Test compilation errors
5. 🟡 Use MKPointOfInterestCategory filters
6. 🟡 SettingsManager async init
7. 🟡 Overlap label width estimate
