# EV80 Chargers — Project Context

## What we're building
An Android app (Flutter) showing EV charging stations in Germany (later Europe) on a map, with filtering by hardware manufacturer/model and charging network operator.

## Tech Stack
- **Framework:** Flutter (Dart) — targets Android first, iOS later
- **Maps:** OpenStreetMap via `flutter_map` package (free, no billing)
- **Data source:** goingelectric.de API (`https://api.goingelectric.de`)
  - API key: already obtained
  - Free/community tier — treat key as a secret (never commit to git)

## Core Features (v1)
- Map view of EV charging stations
- Filter by:
  - Charging hardware manufacturer (e.g. ABB, Alfen, Keba)
  - Charging hardware model (e.g. ABB Terra 54)
  - Charging network / operator (e.g. Ionity, EnBW, Fastned)
- Tap a station → basic detail view (connectors, address, network)

## Out of Scope for v1
- Navigation / "open in maps" button
- Favorites / bookmarks
- Route planning
- User check-ins / availability status
- iOS release (architecture should support it later)

## Geographic Scope
- v1: Germany
- Later: broader Europe

## Key Files
- Design spec: `docs/superpowers/specs/2026-06-08-ev-charger-app-design.md`
- API key: stored in `.env` as `GE_API_KEY` (gitignored, never commit)
