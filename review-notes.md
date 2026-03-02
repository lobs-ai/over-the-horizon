# Diagnostic Review — Apple Maps POI Search + Location Data Model

**Task ID:** `313AC40E-E9AB-4621-B967-93BA7D106B4A`  
**Date:** 2026-03-02

---

## Root Cause of Failures

**The task actually succeeded.** All required code is present:

- `LocationCategory.swift` — Full enum with all 25 categories, no restaurants/food
- `POILocation.swift` — Data model with name, coordinate, category, distance, bearing, prominence
- `POISearchManager.swift` — MKLocalSearch integration, configurable radius, periodic re-search on movement

The "Session not found" error is an **orchestration infrastructure error** — the programmer agent completed the work but the session tracking it died (timeout/crash), so the orchestrator never received the success signal and retried unnecessarily.

---

## Code Quality

### Good ✅
- `LocationCategory.mkCategory` mapping handles Apple API gaps reasonably
- Bearing math (atan2 spherical) is correct
- searchRadiusMiles clamped to 1-5 mi
- Proper @Published / ObservableObject pattern

### Issues Found

#### 🟡 25 sequential MKLocalSearch calls (one per category)
`searchCategory()` fires 25 separate NL queries. Rate-limit risk, very slow.
**Fix:** Use `MKLocalPointOfInterestFilter(including:)` with `pointOfInterestFilter` on the request — batch into 1-2 searches.

#### 🟡 naturalLanguageQuery used instead of category filter
The `mkCategory` mappings on `LocationCategory` exist but are unused. NL queries for "viewpoint", "ferry terminal" etc. are unreliable.
**Fix:** Switch to filter-based search using the existing `mkCategory` mappings.

#### 🔵 No deduplication
Same POI can appear across multiple category searches. No coordinate+name dedup.

---

## Recommendation

**The original task is DONE. Do not retry it.**

Mark it complete. Create a follow-up task for search efficiency.

---

## Handoff (for programmer)

Fix POISearchManager to use MKLocalPointOfInterestFilter instead of 25 NL queries.
Use the existing `mkCategory` mappings. Add deduplication by coordinate+name.
Files: POISearchManager.swift, LocationCategory.swift
