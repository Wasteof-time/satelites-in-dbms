# Orbital Intelligence System

MariaDB catalog for satellite tracking. Python pulls CelesTrak, stores history, and a CLI runs search, collision-style alerts, and reports.

See `architecture.md` for the shape of the system and `plan.md` for the build order.

## Stack

- MariaDB 11 (`ois_db`)
- Python 3.10+ with `requests` and `mysql-connector-python`
- CelesTrak GP JSON (cached under `cache/` while developing)

## Quick Start (Linux)

Clone and run the automated installer:

```bash
chmod +x setup.sh
./setup.sh
```

This automatically:
- Checks Python 3.8+ and Docker
- Configures `.env`
- Starts the MariaDB container (`docker compose up -d`)
- Sets up `.venv` and installs dependencies
- Bootstraps the database schema and ingests telemetry
- Installs the global `ois` and `satellites` commands in `~/.local/bin/` and creates `./ois`

Once installed, you can launch the system from anywhere by typing `ois` or `./ois`.

---

## Manual Setup (Cross-Platform)

```bash
# 1. Database
docker compose up -d

# 2. Python env
python3 -m venv .venv
source .venv/bin/activate    # On Windows: .\.venv\Scripts\Activate.ps1
pip install -r requirements.txt

# 3. Environment
cp .env.example .env

# 4. Schema + dummy rows
python -m app --init-db

# 5. Ingest (uses cache if present; --live hits CelesTrak)
python -m app --sync

# 6. Launch
python -m app
```

## CLI menu

1. View satellite (NORAD ID or name)
2. Search (operator / status / type)
3. View alerts (optional recalculate)
4. Sync from API or cache
5. Generate report (operator, type, debris, trajectory, sync log)
6. Exit

Non-interactive flags: `--init-db`, `--sync`, `--live`, `--alerts`, `--view TERM`, `--report operator|type|debris|sync`.

## Layout

```
sql/schema.sql          tables, FKs, CASCADE
sql/seed.sql            dummy rows for a first demo
ingest/celestrak.py     fetch → parse → upsert
app/cli.py              menu
app/queries.py          alerts, reports, projection
cache/                  CelesTrak JSON while developing
docs/viva.md            viva talking points
docs/er.dbml            paste into dbdiagram.io
```

## Definition of done

A live MariaDB instance, one Python sync from CelesTrak (live or cached), and a CLI collision-style report — without using the `mysql` shell.
