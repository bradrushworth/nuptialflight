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
     runtime schema (forecast + leadup + lat/lon/lead_up_days), keyed by the
     flight's own `_key` so reruns are idempotent upserts.

Cost control: `--positives-only` skips the ~212k negatives (they add nothing
for lead-up features), `--limit` caps the run, `--since` bounds the date range,
`--days N` sets the lead-up window (default 2, matching the app), `--rps`
throttles to the subscription rate limit.

Usage:
  pip install python-arango requests
  export OPENWEATHERMAP_API_KEY=...
  python scripts/backfill_leadup.py --positives-only --days 2 --rps 1

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
DEFAULT_RPS = 1.0         # One Call by Call limit is 60/min => ~1/s (#26)
ONE_DAY = 86400            # seconds

# Dart Daily.toJson key set - both writers must emit the same shape (#27).
DAILY_KEYS = ["dt", "sunrise", "sunset", "moonrise", "moonset", "moon_phase",
              "summary", "temp", "feels_like", "pressure", "humidity",
              "dew_point", "wind_speed", "wind_deg", "wind_gust", "weather",
              "clouds", "pop", "uvi", "rain"]


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
    # the sighting metadata, so transfer stays small. `f.current_weather`
    # never existed in the flights schema (#27) so it is not projected.
    clauses.append(
        "RETURN {"
        "key: f._key, flight: f.flight, size: f.size, "
        "version: f.version, device_id: f.device_id, install_id: f.install_id, "
        "dt: f.weather.daily[0].dt, lat: f.weather.lat, lon: f.weather.lon, "
        "forecast: f.weather"
        "}"
    )
    aql = "\n".join(clauses)
    cursor = db.aql.execute(aql, bind_vars=bind, batch_size=1000)
    return list(cursor)


def precip(value):
    """Normalise a rain/snow style OWM field: bare number or {'1h': n}."""
    if isinstance(value, (int, float)):
        return value
    if isinstance(value, dict) and isinstance(value.get("1h"), (int, float)):
        return value["1h"]
    return None


def normalize_daily_record(rec):
    """Clamp a raw OWM daily record to the Dart `Daily.toJson` key set."""
    out = {k: rec[k] for k in DAILY_KEYS if k in rec}
    out["rain"] = precip(rec.get("rain"))
    return out


def leadup_window(report_dt, days):
    """Return (start, end) epochs: end is the UTC-day floor of report_dt,
    start is `days` days before it. Flooring avoids the report day leaking
    into the lead-up window via a midday-anchored report timestamp (#28)."""
    end = (int(report_dt) // ONE_DAY) * ONE_DAY
    return end - days * ONE_DAY, end


def filter_leadup(records, end_epoch):
    """Keep only records strictly before end_epoch (defensively excludes the
    report day even if the API were to return it, #28)."""
    return [r for r in (records or [])
            if isinstance(r.get("dt"), (int, float)) and r["dt"] < end_epoch]


def fetch_leadup_owm(lat, lon, start, days, api_key):
    """One Call 4.0 /timeline/1day anchored at `start` for `days` records.

    Returns the raw `data` array (list of daily records) or None on failure.
    The 4.0 page cap is 10 records, so `days` must be <= 10.
    """
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
        raise ValueError(f"OWM HTTP {resp.status_code}: {resp.text[:200]}")
    body = resp.json()
    return body.get("data")


def build_leadup_doc(row, leadup_daily, days):
    """Build the enriched `leadup` doc mirroring the app's runtime schema."""
    return {
        "_key": row["key"],                        # idempotent upsert (#25)
        "source": "backfill",
        "flight": row.get("flight", "unknown"),
        "size": row.get("size"),
        "version": row.get("version"),
        "device_id": row.get("device_id"),
        "install_id": row.get("install_id"),
        "lat": row.get("lat"), "lon": row.get("lon"),
        "lead_up_days": days,
        "collected_at": int(time.time() * 1000),
        "weather": {
            "forecast": row.get("forecast"),
            "leadup": {"lat": row.get("lat"), "lon": row.get("lon"),
                       "daily": [normalize_daily_record(r) for r in leadup_daily]},
        },
    }


def pace(state, min_interval):
    """Sleep just enough to keep calls at least `min_interval` seconds apart.

    Called immediately before every HTTP request so no code path (success,
    error, or retry) can bypass the subscription rate limit (#26).
    """
    now = time.monotonic()
    last_call = state.get("last_call")
    if last_call is not None:
        elapsed = now - last_call
        remaining = min_interval - elapsed
        if remaining > 0:
            time.sleep(remaining)
    state["last_call"] = time.monotonic()


def fetch_with_retries(lat, lon, start, days, api_key, pace_state, min_interval):
    """Fetch lead-up data with up to 3 attempts, pacing before each request.

    Returns the raw `data` list, or None if all attempts failed (caller
    should queue the row for the end-of-run retry pass).
    """
    for attempt in range(1, 4):
        pace(pace_state, min_interval)
        try:
            return fetch_leadup_owm(lat, lon, start, days, api_key)
        except RateLimitError:
            print(f"  rate-limited (HTTP 429), attempt {attempt}/3 — sleeping 60s",
                  file=sys.stderr)
            if attempt < 3:
                time.sleep(60)
        except (requests.RequestException, ValueError) as exc:
            print(f"  fetch error, attempt {attempt}/3: {exc}", file=sys.stderr)
            if attempt < 3:
                time.sleep(5)
    return None


def process_row(row, days, api_key, pace_state, min_interval, leadup_coll, dry_run):
    """Fetch + write the leadup doc for a single row.

    Returns one of 'wrote', 'skipped', 'empty', or 'error' (all fetch
    attempts failed — caller should queue the row for an end-of-run retry).
    """
    report_dt = row.get("dt")
    lat, lon = row.get("lat"), row.get("lon")
    if not report_dt or lat is None or lon is None:
        return "skipped"

    start, end = leadup_window(report_dt, days)
    data = fetch_with_retries(lat, lon, start, days, api_key, pace_state, min_interval)
    if data is None:
        return "error"

    leadup_daily = filter_leadup(data, end)
    if not leadup_daily:
        return "empty"

    doc = build_leadup_doc(row, leadup_daily, days)
    if dry_run:
        print(f'  {row["key"]}: {len(leadup_daily)} lead-up days (dry-run)')
    else:
        leadup_coll.insert(doc, overwrite=True)
        print(f'  {row["key"]}: wrote {len(leadup_daily)} lead-up days')
    return "wrote"


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
    parser.add_argument('--dry-run', action='store_true', help='fetch only, do not create the collection or write to ArangoDB')
    args = parser.parse_args()

    days = max(1, min(args.days, 10))
    api_key = env('OPENWEATHERMAP_API_KEY')
    if not api_key:
        sys.exit('OPENWEATHERMAP_API_KEY env var is required')

    since_ms = None
    if args.since:
        since_ms = int(dt.datetime.strptime(args.since, '%Y-%m-%d')
                       .replace(tzinfo=dt.timezone.utc).timestamp() * 1000)

    # Always connect: --dry-run still needs to read flights (and the
    # already-done keys) — it only skips the collection create + insert (#29).
    db = connect_arango()
    leadup_coll = None
    done = set()
    if args.dry_run:
        existing = {c["name"] for c in db.collections()}
        if "leadup" in existing:
            done = set(db.aql.execute("FOR d IN leadup RETURN d._key"))
    else:
        leadup_coll = ensure_leadup_collection(db)
        done = set(db.aql.execute("FOR d IN leadup RETURN d._key"))

    print(f'fetching flights (positives_only={args.positives_only}, since={args.since}, '
          f'limit={args.limit}) ...', flush=True)
    rows = fetch_flight_rows(db, since_ms, args.positives_only, args.limit)
    print(f'{len(rows)} flights to backfill ({days}-day lead-up window)', flush=True)

    min_interval = 1.0 / args.rps if args.rps > 0 else 0
    pace_state = {}
    counts = {"wrote": 0, "skipped": 0, "empty": 0, "errors": 0, "done": 0}
    retry_rows = []

    for row in rows:
        if row.get("key") in done:
            counts["done"] += 1
            continue
        status = process_row(row, days, api_key, pace_state, min_interval,
                              leadup_coll, args.dry_run)
        if status == "error":
            retry_rows.append(row)
        else:
            counts[status] += 1

    if retry_rows:
        print(f'\nretrying {len(retry_rows)} failed row(s) once more ...', flush=True)
        for row in retry_rows:
            status = process_row(row, days, api_key, pace_state, min_interval,
                                  leadup_coll, args.dry_run)
            counts[status if status != "error" else "errors"] += 1

    print(f'\nDone. wrote={counts["wrote"]} skipped={counts["skipped"]} '
          f'empty={counts["empty"]} errors={counts["errors"]} '
          f'already-done={counts["done"]} (total={len(rows)}, days={days})', flush=True)


if __name__ == '__main__':
    main()
