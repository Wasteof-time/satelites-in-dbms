"""Menu-driven CLI for the Orbital Intelligence System."""

from __future__ import annotations

import argparse
import sys
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from mysql.connector import Error as MySQLError

from app.db import init_schema, ping, settings
from app import queries
from ingest.celestrak import sync as ingest_sync


def _fmt(value) -> str:
    if value is None:
        return "-"
    if isinstance(value, datetime):
        return value.strftime("%Y-%m-%d %H:%M")
    if isinstance(value, float):
        return f"{value:.4f}".rstrip("0").rstrip(".")
    return str(value)


def print_table(rows: list[dict], columns: list[tuple[str, str]] | None = None) -> None:
    if not rows:
        print("  (no rows)")
        return
    if columns is None:
        keys = list(rows[0].keys())
        columns = [(k, k) for k in keys]
    widths = []
    for key, header in columns:
        width = len(header)
        for row in rows:
            width = max(width, len(_fmt(row.get(key))))
        widths.append(min(width, 36))
    header_line = "  ".join(header.ljust(w) for (_, header), w in zip(columns, widths))
    rule = "  ".join("-" * w for w in widths)
    print(header_line)
    print(rule)
    for row in rows:
        print(
            "  ".join(_fmt(row.get(key))[:w].ljust(w) for (key, _), w in zip(columns, widths))
        )


def banner() -> None:
    cfg = settings()
    print()
    print("=" * 56)
    print("  Orbital Intelligence System")
    print(f"  {cfg['database']} @ {cfg['host']}:{cfg['port']}")
    print("=" * 56)


def menu() -> None:
    print()
    print("  1) View satellite")
    print("  2) Search")
    print("  3) View alerts")
    print("  4) Sync from API / cache")
    print("  5) Generate report")
    print("  6) Exit")


def view_flow() -> None:
    term = input("  NORAD ID or name: ").strip()
    if not term:
        print("  Nothing entered.")
        return
    sat = queries.view_satellite(term)
    if not sat:
        print(f"  No satellite matched '{term}'.")
        return
    print()
    print(f"  {sat['Name']}  NORAD {sat['NORAD_ID']}  [{sat['Sat_Type']}]")
    print(f"  Operator : {_fmt(sat['Operator'])}")
    print(f"  Status   : {_fmt(sat['Status'])}    Launch: {_fmt(sat['Launch_Date'])}")
    print(
        f"  Orbit    : i={_fmt(sat['Inclination'])}°  e={_fmt(sat['Eccentricity'])}  "
        f"apogee={_fmt(sat['Apogee_km'])} km  perigee={_fmt(sat['Perigee_km'])} km"
    )
    print(f"  Epoch    : {_fmt(sat['Epoch'])}")
    if sat["Sat_Type"] == "comm":
        print(f"  Comm     : band={_fmt(sat['Band'])}  transponders={_fmt(sat['Transponders'])}")
    elif sat["Sat_Type"] == "nav":
        print(f"  Nav      : {_fmt(sat['Constellation'])}  {_fmt(sat['Signal_Type'])}")
    elif sat["Sat_Type"] == "eo":
        print(f"  EO       : sensor={_fmt(sat['Sensor'])}  res={_fmt(sat['Resolution_m'])} m")
    elif sat["Sat_Type"] == "sci":
        print(f"  Science  : {_fmt(sat['Mission'])} / {_fmt(sat['Instrument'])}")
    print("  Recent positions:")
    print_table(
        sat["recent_positions"],
        [("Observed_At", "When"), ("Lat", "Lat"), ("Lon", "Lon"), ("Alt_km", "Alt km")],
    )
    if sat["maneuvers"]:
        print("  Maneuvers:")
        print_table(
            sat["maneuvers"],
            [("Maneuver_At", "When"), ("Type", "Type"), ("Notes", "Notes")],
        )


def search_flow() -> None:
    operator = input("  Operator contains (blank = any): ").strip() or None
    status = input("  Status [active/inactive/decayed/unknown, blank = any]: ").strip() or None
    sat_type = input("  Type [comm/nav/eo/sci, blank = any]: ").strip() or None
    rows = queries.search_satellites(operator=operator, status=status, sat_type=sat_type)
    print()
    print_table(
        rows,
        [
            ("NORAD_ID", "NORAD"),
            ("Name", "Name"),
            ("Operator", "Operator"),
            ("Status", "Status"),
            ("Sat_Type", "Type"),
            ("Inclination", "Incl"),
            ("Apogee_km", "Apogee"),
            ("Perigee_km", "Perigee"),
        ],
    )
    print(f"  {len(rows)} satellite(s)")


def alerts_flow() -> None:
    refresh = input("  Recalculate from latest positions? [y/N]: ").strip().lower()
    if refresh == "y":
        made = queries.generate_collision_alerts()
        print(f"  Wrote {len(made)} alert(s).")
    rows = queries.list_alerts()
    print()
    print_table(
        rows,
        [
            ("Detected_At", "When"),
            ("Status", "Status"),
            ("Object_A", "Object A"),
            ("Object_B", "Object B"),
            ("Distance_km", "Dist km"),
            ("Probability", "P %"),
        ],
    )


def sync_flow() -> None:
    choice = input("  Source [cache/live] (default cache): ").strip().lower() or "cache"
    live = choice == "live"
    print("  Syncing…")
    result = ingest_sync(live=live)
    print(
        f"  {result['status']}: {result['upserted']} satellites, "
        f"{result['history']} positions, {result['debris']} debris "
        f"({result['source']})"
    )
    made = queries.generate_collision_alerts()
    print(f"  Collision check: {len(made)} pair(s) stored.")


def report_flow() -> None:
    print("  a) Satellites by operator")
    print("  b) Satellites by type")
    print("  c) Debris count trend")
    print("  d) Trajectory projection")
    print("  e) Sync log")
    pick = input("  Report: ").strip().lower()
    print()
    if pick == "a":
        print_table(queries.report_by_operator())
    elif pick == "b":
        print_table(queries.report_by_type())
    elif pick == "c":
        print_table(queries.report_debris_trend())
    elif pick == "d":
        term = input("  NORAD ID or name: ").strip()
        minutes = input("  Minutes ahead (default 10): ").strip()
        minutes_n = int(minutes) if minutes.isdigit() else 10
        proj = queries.project_trajectory(term, minutes=minutes_n)
        if not proj:
            print("  No satellite matched.")
            return
        if "reason" in proj:
            print(f"  {proj['reason']}")
            return
        print(f"  {proj['Name']}  NORAD {proj['NORAD_ID']}")
        print(f"  Last two samples → +{proj['minutes']} min")
        print_table(
            [
                {"label": "older", **{k: proj["from"][k] for k in ("Observed_At", "Lat", "Lon", "Alt_km")}},
                {"label": "newer", **{k: proj["to"][k] for k in ("Observed_At", "Lat", "Lon", "Alt_km")}},
                {
                    "label": "projected",
                    "Observed_At": proj.get("projected_at"),
                    **proj["projected"],
                },
            ],
            [
                ("label", ""),
                ("Observed_At", "When"),
                ("Lat", "Lat"),
                ("Lon", "Lon"),
                ("Alt_km", "Alt km"),
            ],
        )
        print(f"  Note: {proj['note']}")
    elif pick == "e":
        print_table(queries.sync_log())
    else:
        print("  Unknown report.")


def loop() -> None:
    ping()
    banner()
    while True:
        menu()
        choice = input("  Select: ").strip()
        print()
        try:
            if choice == "1":
                view_flow()
            elif choice == "2":
                search_flow()
            elif choice == "3":
                alerts_flow()
            elif choice == "4":
                sync_flow()
            elif choice == "5":
                report_flow()
            elif choice == "6":
                print("  Bye.")
                return
            else:
                print("  Enter 1–6.")
        except MySQLError as exc:
            print(f"  Database error: {exc}")
        except FileNotFoundError as exc:
            print(f"  {exc}")
        except Exception as exc:
            print(f"  {exc}")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Orbital Intelligence System CLI")
    parser.add_argument("--init-db", action="store_true", help="Apply schema.sql + seed.sql")
    parser.add_argument("--sync", action="store_true", help="Run ingest (cache unless --live)")
    parser.add_argument("--live", action="store_true", help="With --sync, fetch CelesTrak")
    parser.add_argument("--alerts", action="store_true", help="Recalculate and print alerts")
    parser.add_argument(
        "--report",
        choices=["operator", "type", "debris", "sync"],
        help="Print a report and exit",
    )
    parser.add_argument("--view", metavar="TERM", help="View a satellite by NORAD or name")
    args = parser.parse_args(argv)

    if args.init_db:
        init_schema()
        print("Schema and seed applied.")
        return 0

    ping()

    if args.sync:
        result = ingest_sync(live=args.live)
        print(
            f"Sync {result['status']}: {result['upserted']} satellites, "
            f"{result['history']} history, {result['debris']} debris ({result['source']})"
        )
        queries.generate_collision_alerts()

    if args.view:
        sat = queries.view_satellite(args.view)
        if not sat:
            print(f"No satellite matched '{args.view}'.")
            return 1
        print(f"{sat['Name']}  NORAD {sat['NORAD_ID']}  [{sat['Sat_Type']}]  {sat['Operator']}")
        return 0

    if args.alerts:
        if not args.sync:
            queries.generate_collision_alerts()
        print_table(
            queries.list_alerts(),
            [
                ("Detected_At", "When"),
                ("Status", "Status"),
                ("Object_A", "Object A"),
                ("Object_B", "Object B"),
                ("Distance_km", "Dist km"),
                ("Probability", "P %"),
            ],
        )
        return 0

    if args.report:
        mapping = {
            "operator": queries.report_by_operator,
            "type": queries.report_by_type,
            "debris": queries.report_debris_trend,
            "sync": queries.sync_log,
        }
        print_table(mapping[args.report]())
        return 0

    if args.sync:
        return 0

    loop()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
