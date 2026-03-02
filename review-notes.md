# Code Review — Over the Horizon
**Reviewer:** Reviewer Agent  
**Date:** 2026-03-02  
**Scope:** Full app review — code quality, performance, spec compliance, privacy

---

## Summary

Good architecture overall — clean separation of concerns, solid test coverage for most layers. However there are **two critical bugs** that break core functionality, **one important logic bug** in periodic refresh, and **compile errors** in the test suite. These need to be fixed before shipping.

---

## 🔴 Critical

### 1. MotionManager heading is non-functional for AR
**File:** `MotionManager.swift`

The heading uses `CMAttitude.yaw` converted to degrees. `yaw` is relative to the device's **arbitrary startup orientation**, not magnetic north. If the user opens the app facing west, "west" reads as ~0°. AR labels appear at completely wrong positions.

**Fix:** Use `CLLocationManager.startUpdatingHeading()` and publish `CLHeading.trueHeading`. This is the most critical bug — the core AR feature is broken without accurate compass heading.

### 2. Test compile errors (AROverlayView + POILabelView initializers)
**File:** `OverTheHorizonTests.swift`

`AROverlayView` requires `zoomGestureManager:` but tests omit it. `POILabelView` requires `adjustedPosition:` and `zIndex:` but tests omit both. Large portions of the AR test suite won't compile.

---

## 🟡 Important

### 3. Periodic timer refresh ignores user category settings
**File:** `POISearchManager.swift`, `checkForMovementAndSearch()`

`await searchPOIs()` with no args defaults to `allCases`, ignoring user's Settings selections. User disables a category, walks 500m, timer fires — disabled categories come back. Fix: `await searchPOIs(for: categoriesToSearch)`.

### 4. MKLocalSearch uses text query instead of MKLocalPointOfInterestFilter
**File:** `POISearchManager.swift`

`naturalLanguageQuery = category.rawValue` (e.g. "landmark") matches business names, not categories. A restaurant named "The Landmark Grill" appears as a landmark POI. `LocationCategory.mkCategory` is defined but never used. Use `MKLocalPointOfInterestFilter` with the proper category on iOS 17+.

### 5. Concurrent search race condition — no isSearching guard
**File:** `POISearchManager.swift`

No guard prevents concurrent `searchPOIs()` calls. Timer can fire mid-search causing two async chains to both write `self.pois`. Fix: `guard !isSearching else { return }` at start of `searchPOIs()`.

### 6. OverlapResolver uses 60pt fixed label width — long names still overlap
**File:** `OverlapResolver.swift`

`minLabelWidth = 60.0` is too small. "Philadelphia Museum of Art" renders ~220pt wide. Two such labels will visually overlap even when resolver considers them non-overlapping. Increase minimum or estimate from name length.

---

## 🔵 Suggestions

- **Debug HUD in production**: Lat/Lon, heading, zoom readouts visible to users. Hide with `#if DEBUG` or remove.
- **Search radius vs. display range mismatch**: Search capped at 5 miles (~8km) but display range is 50km default. Users see a 50km overlay but only get POIs from 8km.
- **POI bearing stale between searches**: Bearing/distance stored at search time. Consider re-computing from live location each render frame for nearby POIs.
- **Unused variable in MotionManager**: `private let locationManager = CoreMotion.CMHeadingFilterValueDefault` — misleading name, unused, should be removed.
- **ContentView init creates redundant StateObject instances**: Declare properties without defaults when overriding in `init()`.

---

## What's Done Well

- **Clean pure-value types**: `ARLabelPositioner`, `POIScorer`, `OverlapResolver`, `ZoomGestureManager` are stateless, testable, correct.
- **Bearing math**: `normalizeBearingDifference` handles 0/360 wraparound correctly.
- **Test depth**: 80+ test cases, good edge case coverage (distance ranges, zoom transitions, bearing wraparound).
- **Privacy**: No external network calls, only Camera + Location permissions, no PII in logs.
- **Zoom pinch delta approach**: Correctly uses `scaleDelta = value / lastMagnificationScale` for MagnificationGesture cumulative reporting.
- **Settings persistence**: Clean UserDefaults with defaults-first initialization.
