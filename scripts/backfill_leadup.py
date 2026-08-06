#!/usr/bin/env python3
"""
Backfill the `leadup` ArangoDB collection for historical `flights` rows.

The app's ML training pipeline reads `flights.weather` (forecast daily/hourly),
but the antecedent ("lead-up") daily weather for the days *before* each report
was never collected — docs/model_training_findings.md (Part 4 #3) names this as
the main accuracy lever. Going forward the app collects it for free via
split-and-route (see lib/controller/weather_fetcher.dart); this script
*backfills* it for the years of existing reports in one server-side pass so a
lead-up-augmented model can train on the full history immediately (no need to
wait for new reports to accrue).

For each `flights` row it:
  1. reads the report timestamp (`weather.daily[0].dt` — the report day);
  2. calls One Call API 4.0 `/timeline/1day?start=<report_day - N>&cnt=N`
     (one call per flight, the 4.0 page cap is 10 records so N <= 10);
  3. writes an enriched doc to the `leadup` collection mirroring the app's
     runtime schema (current + forecast + leadup + lat/lon/lead_up_days).

Cost control: `--positives-only` skips the ~212k negatives (they add nothing
for lead-up features), `--limit` caps the run, `--since` bounds the date range,
`--days N` sets the lead-up window (default 2, matching the app), `--rps`
throttles to the subscription rate limit.

Usage:
  pip install python-arango requests
  export OPENWEATHERMAP_API_KEY=...
  python scripts/backfill_leadup.py --positives-only --days 2 --rps 40

Requires these env vars (same defaults the app uses in arangodb.dart):
  ARANGO_URL, ARANGO_DB_NAME, ARANGO_USER, ARANGO_PASSWORD, OPENWEATHERMAP_API_KEY
"""
import argparse
import os
import sys
import time
import datetime as dt

try:
    from arango import ArangoClient
except ImportError:
    sys.exit("python-arango is required: pip install python-arango requests")


class RateLimitError(Exception):
    pass

try:
    import requests
except ImportError:
    sys.exit("requests is required: pip install python-arango requests")


OWM_BASE = "https://api.openweathermap.org/data/4.0/onecall/timeline/1day"
DEFAULT_DAYS = 2          # matches WeatherFetcher.leadUpDays (page cap 10)
DEFAULT_RPS = 40           # One Call by Call default rate limit is 60/min => ~1/s
ONE_DAY = 86400            # seconds


def env(name, default=None):
    val = os.environ.get(name)
    return val if val not in (None, "") else default


def connect_arango():
    url = env("ARANGO_URL", "https://api.bitbot.com.au:8530")
    db_name = env("ARANGO_DB_NAME", "nuptialFlight")
    user = env("ARANGO_USER", "nuptialflight")
    password = env("ARANGO_PASSWORD", "")
    if not password:
        sys.exit("ARANGO_PASSWORD env var is required")
    client = ArangoClient(hosts=url)
    return client.db(db_name, username=user, password=password, verify=True)


def ensure_leadup_collection(db):
    """Best-effort create of the `leadup` collection (mirrors arangodb.dart)."""
    existing = {c["name"] for c in db.collections()}
    if "leadup" not in existing:
        db.create_collection("leadup")
        print("created collection 'leadup'")
    return db.collection("leadup")


def fetch_flight_rows(db, since_ms, positives_only, limit):
    """Read flights rows the same way the training pipeline does, projected."""
    bind = {}
    clauses = []
    clauses.append("FOR f IN flights")
    clauses.append("FILTER f.weather != null")
    clauses.append("FILTER f.weather.daily != null AND LENGTH(f.weather.daily) > 0")
    if positives_only:
        clauses.append("FILTER f.flight == 'yes'")
    if since_ms is not None:
        clauses.append("FILTER f.weather.daily[0].dt * 1000 >= @since_ms")
        bind["since_ms"] = since_ms
    clauses.append("SORT f.weather.daily[0].dt")
    if limit is not None:
        clauses.append(f"LIMIT {int(limit)}")
    # Project only the fields we need: the report-day epoch + the forecast +
    # current weather + the sighting metadata, so transfer stays small.
    clauses.append(
        "RETURN {"
        "key: f._key, flight: f.flight, size: f.size, "
        "version: f.version, device_id: f.device_id, install_id: f.install_id, "
        "dt: f.weather.daily[0].dt, lat: f.weather.lat, lon: f.weather.lon, "
        "forecast: f.weather, current: f.current_weather"
        "}"
    )
    aql = "\n".join(clauses)
    cursor = db.aql.execute(aql, bind_vars=bind, batch_size=1000)
    return list(cursor)


def fetch_leadup_owm(lat, lon, report_dt, days, api_key):
    """One Call 4.0 /timeline/1day anchored `days` before the report day.

    Returns the raw `data` array (list of daily records) or None on failure.
    The 4.0 page cap is 10 records, so `days` must be <= 10.
    """
    start = report_dt - days * ONE_DAY
    params = {
        "lat": lat,
        "lon": lon,
        "appid": api_key,
        "units": "metric",
        "start": start,
        "cnt": days,
    }
    resp = requests.get(OWM_BASE, params=params, timeout=30)
    if resp.status_code == 429:
        raise RateLimitError()
    if resp.status_code != 200:
        print(f"  OWM HTTP {resp.status_code}: {resp.text[:200]}", file=sys.stderr)
        return None
    body = resp.json()
    return body.get("data")


def build_leadup_doc(row, leadup_data, days):
    """Build the enriched `leadup` doc mirroring the app's runtime schema."""
    return {
        'flight': row.get('flight', 'unknown'),
        'size': row.get('size'),
        'version': row.get('version'),
        'device_id': row.get('device_id'),
        'install_id': row.get('install_id'),
        'lat': row.get('lat'),
        'lon': row.get('lon'),
        'lead_up_days': days,
        'collected_at': int(time.time() * 1000),
        'weather': {
            'current': row.get('current'),
            'forecast': row.get('forecast'),
            'leadup': {
                'lat': row.get('lat'),
                'lon': row.get('lon'),
                'daily': leadup_data,
            },
        },
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--days', type=int, default=DEFAULT_DAYS,
                        help='lead-up window in days (default %(default)s, max 10 = 4.0 page cap)')
    parser.add_argument('--positives-only', action='store_true',
                        help='only backfill confirmed sightings (flight=="yes") — skips ~212k negatives')
    parser.add_argument('--limit', type=int, default=None, help='cap number of flights to process')
    parser.add_argument('--since', type=str, default=None,
                        help='only flights on/after this date (YYYY-MM-DD)')
    parser.add_argument('--rps', type=float, default=DEFAULT_RPS,
                        help='max One Call requests/second (throttle to subscription limit)')
    parser.add_argument('--dry-run', action='store_true', help='fetch + print, do not write to ArangoDB')
    args = parser.parse_args()

    days = max(1, min(args.days, 10))
    api_key = env('OPENWEATHERMAP_API_KEY')
    if not api_key:
        sys.exit('OPENWEATHERMAP_API_KEY env var is required')

    since_ms = None
    if args.since:
        since_ms = int(dt.datetime.strptime(args.since, '%Y-%m-%d')
                       .replace(tzinfo=dt.timezone.utc).timestamp() * 1000)

    db = connect_arango() if not args.dry_run else None
    leadup_coll = ensure_leadup_collection(db) if db is not None else None

    print(f'fetching flights (positives_only={args.positives_only}, since={args.since}, '
          f'limit={args.limit}) ...', flush=True)
    rows = fetch_flight_rows(db, since_ms, args.positives_only, args.limit)
    print(f'{len(rows)} flights to backfill ({days}-day lead-up window)', flush=True)

    min_interval = 1.0 / args.rps if args.rps > 0 else 0
    ok, skipped, errors = 0, 0, 0
    for i, row in enumerate(rows, 1):
        report_dt = row.get('dt')
        lat, lon = row.get('lat'), row.get('lon')
        if not report_dt or lat is None or lon is None:
            skipped += 1
            continue
        try:
            leadup_data = fetch_leadup_owm(lat, lon, report_dt, days, api_key)
        except RateLimitError:
            print('  rate-limited (HTTP 429) — sleeping 60s', file=sys.stderr)
            time.sleep(60)
            try:
                leadup_data = fetch_leadup_owm(lat, lon, report_dt, days, api_key)
            except RateLimitError:
                print(f'  still rate-limited after retry; skipping {row["key"]}', file=sys.stderr)
                errors += 1
                continue
        if leadup_data is None:
            errors += 1
            continue
        doc = build_leadup_doc(row, leadup_data, days)
        if args.dry_run:
            print(f'  [{i}/{len(rows)}] {row["key"]}: {len(leadup_data)} lead-up days (dry-run)')
        else:
            leadup_coll.insert(doc, overwrite=True)
            print(f'  [{i}/{len(rows)}] {row["key"]}: wrote {len(leadup_data)} lead-up days')
        ok += 1
        time.sleep(min_interval)

    print(f'\nDone. wrote={ok} skipped={skipped} errors={errors} '
          f'(total={len(rows)}, days={days})', flush=True)


if __name__ == '__main__':
    main()
