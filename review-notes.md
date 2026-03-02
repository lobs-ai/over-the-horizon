# Diagnostic Review: Apple Maps POI Search + Location Data Model

**Task:** `313AC40E-E9AB-4621-B967-93BA7D106B4A`  
**Date:** 2026-03-02

## Root Cause of Failure

**The task actually succeeded.** The "Session not found" error is an orchestrator-level session tracking issue — programmer agent sessions were crashing/timing out at the infra level, causing the orchestrator to mark them as failures even though code was committed.

All three required files exist and are complete:
- `OverTheHorizon/LocationCategory.swift` — full enum with all 25 categories
- `OverTheHorizon/POILocation.swift` — complete model with bearing/distance calculation  
- `OverTheHorizon/POISearchManager.swift` — full MKLocalSearch implementation

## Code Review Findings

### ✅ What's Good
- `LocationCategory` covers all required types and correctly excludes restaurants/food
- `POILocation.calculateBearing()` uses correct spherical math
- `POISearchManager` handles periodic re-search on significant movement (500m threshold)
- Search radius is configurable (1–5 miles, default 5)
- Error handling present per-category
- `@available(iOS 17.0, *)` guard on `mkCategory`

### 🟡 Issues Found

**1. `mkCategory` defined but unused — natural language query used instead**  
`searchCategory()` uses `naturalLanguageQuery = category.rawValue` (raw string) instead of `MKPointOfInterestFilter`. This means category filtering is approximate and could return food/restaurant results anyway. Should use `MKLocalPointOfInterestFilter(including:)` with mapped `MKPointOfInterestCategory` values.

**2. No deduplication of POI results**  
Searching 25 categories separately will return many duplicate real-world places (e.g. a national park appears under park, trailhead, viewpoint, landmark). Each gets a new UUID so deduplication never happens. Deduplicate by coordinate proximity before appending.

**3. Timer scheduling may fail off main thread**  
`setupPeriodicSearch()` is called from `init`. `Timer.scheduledTimer` requires a run loop. If init isn't on main thread, the timer silently never fires.

**4. Missing tests**  
No tests for `calculateBearing`, `calculateDistance`, category mapping, or search manager logic.

### 🔵 Minor
- `campground` grouped under `.sportsAndRecreation` — should be `.natureAndOutdoors`
- `ferryTerminal` maps to `.park` in mkCategory with no comment explaining the fallback

## Recommendation

**Do NOT retry the original task** — the code is already implemented. The "Session not found" error is an orchestrator/infra bug, not a code failure.

**Create follow-up programmer task** for issues #1 (use MKPointOfInterestFilter) and #2 (deduplication) as they affect search correctness.

**Infra fix needed:** Orchestrator should classify "Session not found" as an infra error and not count it as agent failure retries.
