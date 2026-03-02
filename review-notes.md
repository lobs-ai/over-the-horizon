# Diagnostic Review: Apple Maps POI Search + Location Data Model

**Task ID:** `313AC40E-E9AB-4621-B967-93BA7D106B4A`  
**Date:** 2026-03-02  
**Reviewer:** Reviewer Agent

---

## Root Cause of Failure

**"Session not found" is an orchestration/infrastructure error, not a code error.**

Programmer agent sessions were terminated or expired before they could report completion. The code *was* written — all three target files exist with complete implementations. The task appears to have succeeded at the file-write level but the agents couldn't report back.

**Current state:**
- `LocationCategory.swift` ✅ Complete
- `POILocation.swift` ✅ Complete
- `POISearchManager.swift` ✅ Complete

---

## Code Review Findings

### 🔴 Critical

**POISearchManager.swift: 24 sequential MKLocalSearch requests**  
`searchPOIs()` loops over all 24 `LocationCategory.allCases` serially, firing one `MKLocalSearch` per category. MKLocalSearch has rate limits and each call is a network round-trip. On a slow connection this takes 30+ seconds and will hit throttling. Fix: use `MKLocalPointOfInterestFilter` with a single search request covering all desired categories, or at minimum parallelize with `withTaskGroup`.

### 🟡 Important

**POISearchManager.swift: Initial search fires before location is available**  
`setupPeriodicSearch()` is called from `init`, which immediately fires `Task { await searchPOIs() }`. At init time, `locationManager.userLocation` is almost certainly nil. The search silently fails. Should observe location availability and defer first search.

**POISearchManager.swift: NL query instead of pointOfInterestFilter**  
Using `naturalLanguageQuery = category.rawValue` (e.g., "park", "museum") is less reliable than `MKLocalSearch.Request.pointOfInterestFilter`. The NL approach can return irrelevant results. `mkCategory` is already defined on `LocationCategory` — use it.

**LocationCategory.swift: iOS 17 gate on mkCategory**  
`mkCategory` is `@available(iOS 17.0, *)`. If the app's minimum deployment target is < iOS 17, callers need guards. Needs verification against project settings.

**POILocation.swift: Struct UUID identity instability**  
`id = UUID()` is generated per-instance. Since `Equatable` compares by `id`, copying a `POILocation` struct (as Swift structs do on assignment) creates a new identity — two "same" POIs won't be equal. Consider stable ID from hash(name + coordinate).

### 🔵 Suggestions

- `ferryTerminal` maps to `.park` — semantically odd, comment explaining the fallback would help
- `campground` is in `.sportsAndRecreation` but logically belongs in `.natureAndOutdoors`
- Error messages are overwritten per category; only last failure is visible

---

## Recommendation

**Do NOT retry the original task.** Files already exist. Retrying will re-create or overwrite working code.

**Mark original task complete.** File a follow-up programmer task for the performance issue (24 sequential requests → single batched MKLocalSearch with pointOfInterestFilter). That's the only real bug worth fixing.
