# OIS viva notes

Short answers that match the live schema.

## Why 1:N for Position_History, not M:N?

A position row is one measurement of one satellite. The FK `Satellite_ID` is mandatory and unique to that sample. M:N would mean two satellites sharing a measurement, which is not the domain.

## Why subclass tables instead of extra columns on Satellite?

MariaDB has no inheritance. Comm / Nav / EO / Sci are a disjoint EER specialization. Putting `Band`, `Constellation`, `Sensor`, `Mission` on `Satellite` would leave most columns NULL for every row. Subclass tables keep type-specific attributes off the parent; `Satellite_ID` is both PK and FK.

A satellite is in **at most one** subclass. The app deletes other type rows before inserting the mapped type. There is no discriminator column on `Satellite`; type is derived with `LEFT JOIN`s.

## Why MariaDB?

The abstract names MariaDB. Demo SQL (ENUM, `ON DUPLICATE KEY UPDATE`, `ON DELETE CASCADE`) stays on that dialect.

## What does collision probability mean?

`Collision_Alerts.Probability` is `DECIMAL(5,2)` — a percentage from a simple latest-position distance check (`exp(-distance / 400)`), not a high-fidelity conjunction (no TCA, no covariance). Status is `open` under 500 km, otherwise `watch`. Pairs closer than 0.1 km are skipped: CelesTrak repeats the same TLE for docked ISS/CSS modules, so they are co-located catalog entries, not a conjunction. Good enough for the course; say so if asked.

## Why Sync_Log?

“Automatic updates” is a stored fact: timestamp, source (`celestrak:live` or `celestrak:cache`), row count, success/fail. It is not implied by whatever you last ran in a terminal.

## Why cache CelesTrak?

Rate limits are mild, but a local JSON file makes parse/upsert repeatable offline and keeps the demo from depending on the network.

## Apogee / perigee / lat-lon

Derived from GP mean motion and Kepler’s law during ingest. Positions are a small-e ECI approximation, **not SGP4**. Each sync writes a `Position_History` row stamped with fetch time so the table grows even when the TLE epoch is unchanged. Trajectory projection is linear on the last two of those rows.

## BCNF sketch

| Table | Determinant → attributes |
|-------|--------------------------|
| Satellite | Satellite_ID → all; NORAD_ID → all |
| Orbit_Parameters | Satellite_ID → elements (1:1) |
| Position_History | Position_ID → satellite, time, lat/lon/alt |
| Maneuvers | Maneuver_ID → satellite, time, type |
| Collision_Alerts | Alert_ID → pair, probability, distance, time |
| Debris_Records | Debris_ID → catalog id, parent, first seen |
| Comm/Nav/EO/Sci | Satellite_ID → type attributes |
| Sync_Log | Sync_ID → run metadata |

No repeating groups, no partial dependence on a composite key, no transitive dependence of non-keys on other non-keys. `Operator` is an attribute of Satellite, not a separate entity (acceptable at this scale; 3NF would allow an Operator table if operators gained their own attributes).

## Cardinality recap

- Satellite 1:1 Orbit_Parameters
- Satellite 1:N Position_History, Maneuvers
- Satellite 1:1 (optional) one of Comm / Nav / EO / Sci
- Collision_Alerts references two satellites
- Debris_Records optionally references a parent satellite (`ON DELETE SET NULL`)
