# OIS Implementation Plan

Phased build of the Orbital Intelligence System. Architecture is in `architecture.md`. This file is the build order only.

**Stack:** MariaDB (`ois_db`) · Python 3 · `requests` · `mysql-connector-python`  
**v1 UI:** menu-driven CLI  
**Ingest:** CelesTrak (cached JSON while developing)

---

## Phase overview

| Phase | Time | Outcome |
|-------|------|---------|
| 0 Setup | ½ day | MariaDB, venv, one working CelesTrak fetch |
| 1 Schema | 1 day | All tables, FKs, dummy rows |
| 2 Ingest | 2–3 days | Upsert from CelesTrak into live tables |
| 3 Protocols | 1–2 days | Alerts, reports, simple projection |
| 4 CLI | 1 day | Demo without a SQL shell |
| 5 Submit | 1 day | ER diagram, screenshots, viva notes |

---

## Phase 0 — Setup

**Files:** `ingest/celestrak.py` (print-only), `cache/`, later `requirements.txt`

- [ ] Install MariaDB locally; create empty database `ois_db`
- [ ] Create a Python venv; install `mysql-connector-python`, `requests`
- [ ] Hit one CelesTrak endpoint and print JSON
- [ ] Save that response under `cache/` so later work does not re-hit the API
- [ ] Confirm the MariaDB user the app will use can connect

**Exit:** a script prints CelesTrak JSON and MariaDB accepts a connection. No tables yet.

---

## Phase 1 — Schema

**Files:** `sql/schema.sql`

- [ ] `CREATE TABLE` for the six core tables: `Satellite`, `Orbit_Parameters`, `Position_History`, `Maneuvers`, `Collision_Alerts`, `Debris_Records`
- [ ] Subclass tables: `Comm_Satellite`, `Nav_Satellite`, `EO_Satellite`, `Sci_Satellite` (`Satellite_ID` PK+FK)
- [ ] `Sync_Log` (timestamp, source, row counts, status)
- [ ] `NORAD_ID UNIQUE NOT NULL` on `Satellite`
- [ ] Foreign keys with `ON DELETE CASCADE`
- [ ] Insert a few dummy satellites, one orbit row, a couple of positions, one alert, one debris row

**Exit:** `schema.sql` applies cleanly on a fresh `ois_db`; dummy `SELECT`s join parent → orbit → history.

---

## Phase 2 — Ingest

**Files:** `ingest/celestrak.py`, `cache/`

- [ ] Parse CelesTrak JSON (prefer cache file first, live fetch behind a flag)
- [ ] Upsert `Satellite` on `NORAD_ID`
- [ ] Upsert `Orbit_Parameters` for that satellite
- [ ] Insert a `Position_History` row per satellite in the fetch
- [ ] Write a `Sync_Log` row when the run finishes (success or failure)
- [ ] Map a subset of rows into type subclass tables when the catalog implies a type; otherwise leave type unset

**Exit:** running the ingest script twice does not duplicate satellites; history and `Sync_Log` grow.

---

## Phase 3 — Protocols

**Files:** `app/queries.py`

- [ ] Collision query: latest position per satellite, pair distance / dummy probability, insert into `Collision_Alerts`
- [ ] Report: satellites by operator
- [ ] Report: debris count trend
- [ ] Report: satellites by type (join subclass tables)
- [ ] Simple trajectory projection: linear extrapolation from the last two `Position_History` rows (good enough for the course)

**Exit:** each query returns a readable result set against ingested (or dummy) data.

---

## Phase 4 — CLI

**Files:** `app/cli.py` (calls `app/queries.py` and `ingest/celestrak.py`)

Menu options:

1. View satellite (by `NORAD_ID` or name)
2. Search (operator / status / type)
3. View alerts
4. Sync from API (or cache)
5. Generate report
6. Exit

- [ ] Wire each option to a query or ingest function
- [ ] Print tabular output; no raw SQL shown to the operator
- [ ] Fail clearly if MariaDB is down or cache/API is empty

**Exit:** the definition of done below can be demonstrated from the menu alone.

---

## Phase 5 — Submission polish

**Files:** ER export (draw.io / dbdiagram.io), report screenshots, short viva notes (optional `docs/`)

- [ ] Draw the ER/EER diagram from `architecture.md` (specialization visible)
- [ ] Screenshot working CLI: sync, search, alerts, report
- [ ] Recheck BCNF on the live schema (no hidden repeating groups, keys match the diagram)
- [ ] Viva notes: cardinality, specialization, MariaDB choice, what “probability” means here

**Exit:** report pack + live demo path are ready.

---

## Definition of done

A live MariaDB instance, one Python sync from CelesTrak (live or cached), data in `Satellite` / `Orbit_Parameters` / `Position_History` / `Sync_Log`, and a CLI command that prints a collision-style report — without using the `mysql` shell.

That is the whole abstract, proven live.

---

## Viva checklist

- **Why 1:N for `Position_History`?** A position sample belongs to one satellite. M:N would imply a shared measurement, which is not the domain.
- **Why subclass tables?** MariaDB has no inheritance. Separate type tables keep the EER specialization (Comm / Nav / EO / Sci) without nullable type-specific columns on `Satellite`.
- **Why MariaDB?** Named in the abstract; stay on that dialect for the demo.
- **What is collision probability?** A `DECIMAL(5,2)` percentage from a simple latest-position check, not a high-fidelity conjunction analysis.
- **Why `Sync_Log`?** So “automatic updates” is a stored run history, not only a script you remember running.
- **Why cache CelesTrak?** Rate limits are mild, but a local JSON file makes parse/upsert work repeatable offline.

---

## Optional later (not required for done)

- Space-Track.org (register early if you want it; approval is not instant)
- `sgp4` orbit propagation instead of linear extrapolation
- Streamlit or Flask dashboard on top of the same queries
