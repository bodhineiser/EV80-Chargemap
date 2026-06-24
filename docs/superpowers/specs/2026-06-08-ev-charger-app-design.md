# EV Charger App — Design Spec

**Date:** 2026-06-08
**Status:** Approved

---

## Overview

A Flutter Android app that displays EV charging stations in Germany on an OpenStreetMap map. Users can filter stations by charging network/operator and by hardware manufacturer/model. Tapping a marker shows a detail sheet with connector types, power ratings, network, and hardware info.

v1 targets Germany only. The architecture is country-agnostic so Europe can be added later without structural changes.

---

## Tech Stack

| Concern | Choice | Reason |
|---|---|---|
| Framework | Flutter (Dart) | Android-first, iOS-ready later |
| Maps | `flutter_map` + OSM tiles | Free, no billing, great European coverage |
| State management | `flutter_bloc` (Cubit) | Standard Flutter best practice, testable |
| HTTP | `dio` | Robust, interceptor support for auth header |
| Models | `freezed` + `json_serializable` | Immutable, type-safe, auto-generated JSON |
| DI | `get_it` | Simple service locator |
| Config | `flutter_dotenv` | API key loaded from `.env`, never committed |

---

## Architecture

Four layers, each depending only on the layer below:

```
UI (Screens & Widgets)
        ↕  BlocBuilder / BlocListener
State (StationCubit)
        ↕  method calls
Repository (StationRepository)
        ↕  HTTP via Dio
Data (GoingElectricApiClient + Models)
        ↕  JSON / REST
External: goingelectric.de API + OSM tile server
```

---

## Screens

### 1. Map Screen (`MapScreen`)
- Full-screen `flutter_map` with OSM tiles
- Station markers: green circle with ⚡ icon for single stations, orange numbered circle for clusters
- App bar contains two filter buttons: **Network ▾** and **Hardware ▾**
- Active filter strip below the map: shows current active filter chips with a "× clear" option
- Tapping a marker opens `StationDetailSheet`

### 2. Network Filter Sheet (`NetworkFilterSheet`)
- Modal bottom sheet
- Chip-based multi-select
- "Reset" and "Apply" buttons

### 3. Hardware Filter Sheet (`HardwareFilterSheet`)
- Modal bottom sheet
- Two sections: **Manufacturer** (searchable scrollable list) and **Model** (searchable scrollable list, narrowed by selected manufacturers)
- Data populated by background scraping of goingelectric.de station pages

### 4. Station Detail Sheet (`StationDetailSheet`)
- Modal bottom sheet, slides up on marker tap
- Shows: station name, address, network badge, hardware manufacturer/model badges
- Connector list: each row shows connector type and max power in kW

---

## Data Flow

1. App launches → `StationCubit` fetches CCS stations for the default Germany viewport
2. User pans/zooms → map emits new bounding box → `StationCubit.loadStations(bounds)` called (400ms debounce)
3. `StationRepository` checks in-memory cache. Cache hit → returns immediately. Cache miss → calls `GoingElectricClient`
4. API filters by `plugs[0][type]=combo_typ2` (CCS only)
5. Response parsed into `List<ChargingStation>` → Cubit emits `StationsLoaded`
6. `HardwareScraper` fetches station pages in background (1200ms inter-request delay, 429 exponential backoff)
7. As hardware data arrives via stream → Cubit patches `_allStations` and re-emits filtered state

---

## Data Models

See `lib/core/models/` for freezed model definitions.

---

## API Integration

**Base URL:** `https://api.goingelectric.de`

| Endpoint | Purpose |
|---|---|
| `GET /chargepoints/` | Fetch CCS stations by lat/lng/radius |

API key stored in `.env` as `GE_API_KEY`. Never committed to git.

---

## Out of Scope for v1

- Navigation / "open in maps"
- Favorites / bookmarks
- Route planning
- User check-ins or live availability
- iOS release
- Offline tile caching
