# CLINE.md — Ant Nuptial Flight Predictor

Project context for Cline (AI coding agent) sessions.

## What this is
A Flutter app (Android / iOS / Web) that downloads weather at the user's
location and predicts the likelihood that queen ants are on a nuptial
flight today and for the next week. It also has an Android home-screen
widget and background-fetch notifications.

Repo: https://github.com/bradrushworth/nuptialflight
Web: https://nuptialflight.app/

Current app version: **2.13.9+134** (fix shared_preferences MissingPluginException in tests; 2.13.8+133 response caching + map attribution contrast).
flutter analyze stays at 0 errors (only pre-existing deprecation info-warnings).
flutter analyze stays at 0 errors (only pre-existing deprecation info-warnings).
`flutter analyze` reports 0 errors (only pre-existing deprecation info-warnings).

## Build / tooling notes
- Flutter SDK lives at `C:/Users/Brad/flutter` (not the pub cache).
- The agent's *primary working directory* is often a pub-cache `android`
  folder — always `cd` into the real project
  (`C:/Users/Brad/StudioProjects/nuptialflight`) before git/flutter.
- `flutter analyze` on the whole project takes ~2 min the first time
  (resolves packages). Run it from the project root, not a sub-path,
  otherwise it resolves paths against the wrong CWD.
- `git` must be invoked as `git -C "C:/Users/Brad/StudioProjects/nuptialflight" ...`
  because the shell CWD is not the project.
- Requires `assets/.env` with `OPENWEATHERMAP_API_KEY=<key>`.

## Key source files
- `lib/main.dart` — app entry (`main()`), `MyHomePage` / `_MyHomePageState`.
  Owns the first-page load flow: `_loadData()` -> `_getLocation()` ->
  `_getWeather()` -> `_applyWeather()`. Shows a `CircularProgressIndicator`
  until `loaded == true`. `_getWeather()` fetches current/historical/forecast
  in parallel, derives the lead-up `OneCallResponse` from `fetchWeather()`'s
  split-out past slice, and passes everything to `_applyWeather()`, which
  `setState`s, resolves the place label, and scores every hour/day via
  `lib/controller/scoring.dart` before recording the report to ArangoDB.
- `lib/controller/weather_fetcher.dart` — `WeatherFetcher`: location
  lookup (`findLocation`), and the OpenWeatherMap calls. Uses **One Call API
  4.0** timeline endpoints (`/data/4.0/onecall/timeline/1h` + `/1day`; history
  via `start` in the past, since 4.0 dropped the old `/timemachine` endpoint).
  `fetchNearestWeatherLocation()` still uses the separate Current Weather
  (2.5) API because it supplies the place `name` used for the location label
  (One Call 4.0 has no `name` field). Responses are parsed by the kind-aware
  `OneCallResponse.fromTimelineJson(json, TimelineKind.{hourly,daily})` — no
  `next`/`prev` key lookups.
  **`fetchDailyWeather()`** is the single daily-timeline implementation — one
  paid call — used both by `fetchWeather()` (which composes the hourly leg,
  `cnt=48`, with `fetchDailyWeather()`) and directly by the background
  service (`services.dart`), which never needs hourly.
  **Split-and-route (zero extra calls):** `fetchDailyWeather()` anchors its
  request `leadUpDays` (= 2) into the past (`start = today − leadUpDays`,
  `cnt = leadUpDays + 8` = the 4.0 page cap), so one request holds both the
  antecedent days *and* the 8-day forecast. The pure, unit-tested
  `WeatherFetcher.splitDaily` then splits the combined `data` array at the
  LOCATION-LOCAL day boundary (not UTC): records whose local day is before
  local "today" become the transient `leadUpDaily` field; the rest become
  `daily`, so `daily[0]` is still local *today* (keeping the legacy
  `flights.weather.daily` training schema valid). This collects the
  antecedent ("lead-up") weather the training docs say was never stored
  (model_training_findings.md Part 4 #3) at **zero** extra One Call calls —
  the daily request the app already makes simply reaches a couple of days
  into the past. `_getWeather` derives the `_leadUp` `OneCallResponse` from
  that split and threads it into `createWeather`/`updateWeather`. Raise
  `leadUpDays` beyond 2 and the combined window spills past the 10-record
  page, requiring an extra paginated request.
- `lib/controller/scoring.dart` — length-safe hourly/daily scoring
  (`computeHourlyScores`/`computeDailyScores` and the `*Percentages`
  wrappers `_applyWeather` calls). The forest model runs at most once per
  slot; percentages are derived from those scores, not recomputed. Missing
  slots (the 4.0 endpoints can page shorter than the UI's fixed slot counts)
  zero-fill instead of throwing.
- `lib/controller/arangodb.dart` — ArangoDB reporting of sightings/weather.
  `createWeather()`/`updateWeather()` still write the legacy `flights` /
  `historical` / `current` collections, and now **also** write to a **new
  `leadup` collection** (best-effort auto-created) via one shared
  `_leadUpDoc()` builder used by both the insert and update paths so the
  schema can't drift. Each leadup doc carries `source: 'app'` (vs
  `'backfill'` for the Python backfill script), `lat`/`lon`/`lead_up_days`/
  `collected_at` at the top level, and nested `current`/`forecast`/`leadup`
  weather — the training-ready schema for lead-up-change features
  (days-since-rain, pressure trend, first warm day after rain).
- `scripts/backfill_leadup.py` — normalised Python backfill: re-derives the
  same lead-up window (`--days`, default 2, matching `leadUpDays`) for
  existing `flights` docs via the OWM daily timeline, and upserts into the
  `leadup` collection keyed by the flight's own `_key` (`source: 'backfill'`)
  so reruns are idempotent. Defaults to `--rps 1` (One Call by Call's
  ~60/min limit); `--dry-run` fetches without writing.
- `lib/controller/services.dart` — `initializeService()` (background_fetch
  config + notification channels), `getServicePercentage()`,
  `getReportedFlightsNearMe()`. The background job calls
  `WeatherFetcher.fetchDailyWeather()` directly (daily-only, one paid call).
- `lib/controller/nuptials.dart` — prediction math. `Nuptials` loads two
  RandomForest models; `nuptialDailyPercentageModel` / `nuptialHourlyPercentageModel`
  score weather. (The `models/*.dart` `score()` trees are generated — do not hand-edit.)
- `lib/view/map.dart` — map page.
- `lib/responses/*.dart` — OWM response models.

## First-load performance (work done 2026-07-18)
The first page was slow because the startup path blocked on serialised,
non-rendering work. Fixed in commit `6123340`:
1. `initializeService()` moved to *after* `runApp()` via `unawaited(...)`
   so background-fetch config no longer delays the first frame.
2. Notification-permission request in `_loadData()` is no longer `await`ed
   (wrapped in `unawaited(...)`) — location/weather calls start immediately.
3. `_getLocation()` now does a fast passive `getLastKnownPosition()` first
   and only falls back to an active GPS fix when none exists, avoiding the
   previous double full weather fetch on every launch. Also fixes the
   first-launch case (no cached position) which used to throw.
4. Active-GPS `timeLimit` reduced 30s -> 10s (`weather_fetcher.dart`).

Response caching is implemented in `weather_fetcher.dart` via `_fetchCached`
(`shared_preferences`, keyed by rounded lat/lon). Per-endpoint TTLs: 30 min
current/forecast, 24 h reverse geocode, 30 days historical. Repeat launches
reuse cached responses, cutting paid OWM calls. The daily-forecast
(`fetchDailyWeather`) cache key is additionally anchored to the UTC day
(`dt: todayUtcDay`), so it invalidates once per day regardless of TTL; the
historical cache is namespaced under the `timemachine4` endpoint key (One
Call 4.0 removed the old `/timemachine` endpoint, so history now comes from
the hourly timeline instead).

## Verification
- `flutter analyze` reports 0 errors. The only findings are pre-existing
  `deprecated_member_use` info-warnings in `screenshots_other.dart`,
  `widgets_mobile.dart`, `utils.dart` (use of `dart:html`,
  `registerBackgroundCallback`, `canLaunch`/`launch`). Do not "fix"
  these by upgrading packages unless asked — they are out of scope.
- README.md was expanded (2026-07-18) with features, data flow,
  setup/.env template, and project structure — keep it in sync if you
  add user-facing features or change required API keys.
- `flutter pub upgrade` has been observed to HANG for many minutes
  (stuck resolving git deps). If it does not finish quickly, kill the
  `dart.exe` processes and use `flutter pub get` to reconcile
  `pubspec.lock` instead.
