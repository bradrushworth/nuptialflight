# lib/controller/ — data, scoring, interpretation, services

The logic layer. Nothing here builds widgets; nothing in `view/` should
duplicate what lives here.

## Files

| File | Role |
|---|---|
| `weather_fetcher.dart` | Location + OpenWeatherMap calls, `splitDaily`, response cache |
| `scoring.dart` | Length-safe hourly/daily scoring; forest runs once per slot |
| `nuptials.dart` | Feature-vector construction, PD-curve gauges, size seasonal prior |
| `flight_index.dart` | Percentiles, calibrated odds, the five bands |
| `leadup_features.dart` | The 7 antecedent-weather features (shared by both models) |
| `services.dart` | Background fetch, notifications, widget/tile updates |
| `arangodb.dart` | ArangoDB singleton — reports, nearby flights, `leadup` writes |
| `units.dart` | Metric/imperial display preference |
| `geo.dart` | `syntheticPosition()` helper |
| `install_id.dart` | Anonymous per-install UUID |
| `screenshots_*.dart`, `widgets_*.dart` | Conditional-import platform shims |

## The three things most likely to trip you up

### 1. `splitDaily` is time-zone logic, and it is pure on purpose

One paid daily request is anchored `leadUpDays` (=2) local days in the past
with `cnt = leadUpDays + 8`, so a single call carries both the antecedent
days and the 8-day forecast. It splits at the **location-local** day
boundary, which is what guarantees `daily[0]` is local today and not UTC
today.

It is pure and unit-tested (`test/daily_split_test.dart`) because time-zone
bugs here are invisible in the UI until someone in UTC+13 reports a
one-day-shifted forecast. Keep it pure; don't reach for `DateTime.now()`
inside it.

### 2. Short pages are normal, not exceptional

The One Call 4.0 timeline endpoints page. Hourly/daily lists routinely arrive
shorter than the UI's fixed slot counts. `scoring.dart` zero-fills rather
than throwing — preserve that. Similarly, live 4.0 responses omit fields the
docs imply are always present:

- `/timeline/1day` **never** sends `dew_point` → estimated via
  `estimateDewPoint()` (Magnus-Tetens). A flat `0.0` would blow out `dew_dep`
  on every scored day.
- `pop` is missing on today/past daily records → defaults to `0`, matching
  the training pipeline's `fillna(0)`.
- Integer-typed fields can arrive as doubles → coerced via `_asInt`.

If you see a suspiciously flat score across all days, check for a field that
silently defaulted before suspecting the model.

### 3. `flight_index.dart` decides what users see, more than the model does

The model emits an uncalibrated tree-vote fraction. Everything a user reads —
the band, the "1 in N", the percentile — comes from `flight_stats.json` via
this file. **A UI that looks wrong is more often a calibration issue than a
model issue.**

Two facts that surprise people:

- **`quiet` is the majority band** (~53–79% of days, ~70% typical). That is
  intended honesty, not a bug. Any visual encoding that collapses on a quiet
  day is broken — test with a quiet day.
- **Hourly scores must be banded with `bandForHourly()`, not `bandFor()`.**
  `flight_stats.json` carries a daily block and a sibling `hourly` block
  (quantiles + isotonic), because the two models score different
  distributions — on the 2026-09-05 fit Prime opens at raw 0.70 hourly vs
  0.76 daily. `FlightIndex.hasHourlyStats` is false for assets generated
  before that, in which case everything hourly degrades to the daily tables
  rather than throwing.

- **Hourly bars are still capped at the day's band via `minBand()`**, because
  **the hourly model has no rain or cloud feature** — it cannot see
  precipitation at all. The cap is *not* justified by the daily model being
  more accurate; it isn't. Honest-protocol AUC is 0.671/0.666 (hourly) vs
  0.660/0.639 (daily). See `minBand`'s doc comment and
  [docs/model_training_findings.md](../../docs/model_training_findings.md)
  Parts 5-6 before changing it.

## Paid API calls

Only the One Call 4.0 timeline requests are billed. The budget table is in
the root [AGENTS.md](../../AGENTS.md) — **update it in the same change** if
you add a call to a hot path. Caching is 30-minute TTL with keys including
rounded lat/lon (the daily key is also day-anchored).

## Security

- Never log a URL containing `appid=`. Use `redactUrl()` from
  `lib/utils.dart`. These are bare `print` calls that run in **release**
  builds, so a leak reaches real users' device logs.
- Never commit credentials; `assets/.env` is gitignored.
- `arangodb.dart` degrades gracefully when `ARANGO_PASSWORD` is unset.
