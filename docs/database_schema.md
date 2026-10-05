# ArangoDB schema reference

The backend database (`nuptialFlight` on ArangoDB) is written by the scoped
REST service for migrated clients and directly by older
installed apps and `scripts/backfill_leadup.py`, and read
by the training notebooks (`lib/models/*.ipynb`) and
`scripts/flight_stats_pipeline.py`. This file is the reference for what each
collection holds; keep it in sync with the writers.

## Collections

### `flights` — the training table (legacy schema, FROZEN)

One document per weather recording. `_recordWeather()` writes a
`flight: 'unknown'` doc on every successful weather load (each app open plus
the hourly foreground refresh); submitting a sighting updates that session's
doc to `flight: 'yes'` with a queen `size` (small/medium/large).

```
{ flight: 'unknown'|'yes', size?, version, device_id, install_id,
  weather: { lat, lon, timezone, timezone_offset, daily[8], hourly[48] } }
```

- `weather.daily[0]` is the **location-local today** (guaranteed by
  `WeatherFetcher.splitDaily`); `daily[1..7]` are the forecast. No past days.
- Training reads `tgt: f.flight == 'yes'` — everything else is an implicit
  negative. See `docs/model_training_findings.md` for the label caveats.
- This schema is what years of stored history use. **Do not change it.**

### `leadup` — antecedent weather for ML training (new, One Call 4.0 era)

One enriched document per report carrying the days *before* the report —
the "lead-up" weather the legacy schema never stored. Two writers, one
schema:

```
{ _key?,                 // backfill only: the source flight's _key
  source: 'app'|'backfill',
  flight, size?, version, device_id, install_id,
  lat, lon, lead_up_days, collected_at,
  weather: {
    current?,            // app only (CurrentWeatherResponse snapshot)
    forecast,            // the OneCallResponse the app scored
    leadup: { lat, lon, timezone?, timezone_offset?, daily[lead_up_days] }
  } }
```

- Migrated app path: the service's document builder preserves the legacy
  `_leadUpDoc()` shape. A signed handle reserves all four server-generated
  keys; sighting confirmation can insert leadup when the snapshot lacked it.
- Backfill path: `scripts/backfill_leadup.py` — idempotent upserts keyed by
  the flight's `_key`, daily records normalised to the Dart `Daily.toJson`
  key set (`rain` always a bare number), report day defensively excluded
  from the window, default throttle 1 rps.
- Known accepted divergences between the writers: the app omits the `size`
  key when null (backfill writes `size: null`); the app's `forecast`
  includes `hourly[48]`, the backfill's stored forecast is whatever the
  source flight doc held. Read fields defensively.

### `historical` — the flight day's own hourly weather

- Pre-One-Call-4.0 docs: `{ current, hourly[24] }` (hourly adds
  `visibility`; 3.0-era parser sometimes wrote near-empty docs).
- Since the 4.0 migration: `{ lat, lon, timezone, timezone_offset,
  hourly[~24] }` — no `current`/`minutely` (the 4.0 hourly timeline has no
  such blocks; absent keys are omitted, not null).

### `current` — single Current Weather (2.5) snapshot per report

```
{ flight, version, device_id, install_id, weather: <CurrentWeatherResponse> }
```

## Access notes

- The training user connects with server-side AQL projection
  (`RETURN {field…}`) — ~30x faster than `RETURN f`.
- New 2.29.0 clients contain only the scoped NF app key and anonymous install
  UUID. The REST service and private training tools hold database credentials;
  client bundles do not. Earlier installed builds continue to use direct
  access during the [compatibility period](api-transition.md).
