# 🛰️ OIS Project — Vibe Doc

*Orbital Intelligence System — a DBMS project that's actually kinda cool ngl*

---

## 🎯 The One-Liner

"A centralized MariaDB database for satellite tracking, because right now everyone's
juggling 5 different APIs like it's 2010."

---

## 🧠 Skills You Actually Need

### Core (non-negotiable)
- **SQL / MariaDB** — DDL (CREATE TABLE, constraints, FK/PK), DML, JOINs across your 6 tables, basic transactions
- **Python** — `requests` for hitting APIs, `mysql-connector-python` or `SQLAlchemy` to talk to MariaDB
- **Data parsing** — JSON parsing (most satellite APIs return JSON/TLE format), regex for TLE if you go that route

### API-side
- **CelesTrak API** — free, no auth needed, returns TLE/JSON. Best starting point.
- **Space-Track.org API** — needs login/auth (OAuth-ish session cookies), more authoritative data, rate-limited
- **TLE parsing** — Two-Line Element sets are their own mini-format; look at `sgp4` python lib if you want to actually propagate orbits later

### Nice-to-haves (flex points for viva/demo)
- **Basic orbital mechanics** — know what apogee/perigee/inclination/eccentricity *mean* so you don't freeze when asked
- **ER/EER modeling** — you already did this, just be able to defend the specialization (Comm/Nav/EO/Sci satellites)
- **Simple frontend** — even a basic CLI menu or Streamlit dashboard makes the demo 10x better than raw `mysql` shell

---

## 🗺️ The Plan (Phased, so you don't panic)

### Phase 0 — Setup (½ day)
- [ ] Install MariaDB locally, create `ois_db`
- [ ] Set up Python venv, install `mysql-connector-python`, `requests`, `sgp4` (optional)
- [ ] Get a free CelesTrak endpoint working in a script (just print the JSON)

### Phase 1 — Schema (1 day)
- [ ] Run your CREATE TABLE scripts for all 6 tables (Satellite, Orbit_Parameters,
      Position_History, Maneuvers, Collision_Alerts, Debris_Records)
- [ ] Add FK constraints properly (ON DELETE CASCADE is your friend for a student project)
- [ ] Insert a few dummy rows manually to sanity check

### Phase 2 — The Parser (core deliverable, 2–3 days)
- [ ] Python script: fetch from CelesTrak → parse → INSERT/UPDATE into `Satellite` + `Orbit_Parameters`
- [ ] Handle "satellite already exists" (upsert on NORAD_ID)
- [ ] Log a `Position_History` row per fetch (this is what makes your DB "alive")

### Phase 3 — The Fun Protocols (this is where you get marks)
- [ ] Collision alert query: distance/probability check between two satellites' latest positions (can be dummy logic, doesn't need real physics)
- [ ] "Generate report" query — e.g. all satellites by operator, or debris count trend
- [ ] Basic trajectory projection — even linear extrapolation counts as "prediction" for a DBMS course

### Phase 4 — Wrapper / UI (make it demo-able)
- [ ] Simple menu-driven CLI OR a tiny Streamlit/Flask page
- [ ] Buttons/options mapping to your use cases: View Satellite, Search, View Alerts, Sync from API, Generate Report

### Phase 5 — Polish for submission
- [ ] Actual ER diagram (draw.io / dbdiagram.io — way cleaner than the notebook sketch)
- [ ] Screenshot your working queries for the report
- [ ] Double check BCNF claim actually holds once real data's in there

---

## 🔥 Random Shit / Things to Not Forget

- Your abstract says "MariaDB" — stay consistent, don't accidentally demo on MySQL/PostgreSQL syntax that breaks
- `NORAD_ID` should probably be `UNIQUE` not nullable — decide if a satellite can exist in your DB before it has a NORAD ID assigned
- Collision_Probability as `DECIMAL(5,2)` maxes at 999.99 — fine for a %, just don't overthink it
- Consider adding a `Sync_Log` table (timestamp of last API sync) — free bonus point for "system requirement: automatic updates"
- The EER specialization (Comm/Nav/EO/Sci) — in MariaDB you don't get native inheritance, so you're either:
  - doing separate subclass tables with Satellite_ID as PK+FK (cleaner, recommended), or
  - cramming extra nullable columns into Satellite (lazier, works for a demo)
- CelesTrak rate limits are chill but don't hammer it in a loop while testing — cache responses to a local JSON file while developing
- For the viva: be ready to explain *why* 1:N and not M:N for Satellite→Position_History (a position record only ever belongs to one satellite, duh, but they'll ask anyway)
- Space-Track needs you to register an account — do this early, approval isn't always instant

---

## 🏁 Definition of Done

You can point at a live MariaDB instance, run one Python script that pulls fresh
data from CelesTrak, watch it land in your tables, then run a query that spits out
a "collision alert" style report — all without touching the raw SQL shell.
That's your whole abstract, proven live.