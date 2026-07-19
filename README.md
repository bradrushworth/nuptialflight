# Ant Nuptial Flight Predictor

A Flutter app (Android / iOS / Web) that tells you the best days to go
ant collecting. It downloads the weather at your location and estimates the
likelihood that queen ants are undertaking their nuptial (mating) flights
near you — today and for the next week. When the percentage is high, it's
time to get outside and look for ants in your local area!

- **Web app:** https://nuptialflight.app/
- **Source:** https://github.com/bradrushworth/nuptialflight

<p align="center">
  <img src="https://raw.githubusercontent.com/bradrushworth/nuptialflight/master/assets/Screenshot_1641349717.png" height="540" />
  <img src="https://raw.githubusercontent.com/bradrushworth/nuptialflight/master/assets/Screenshot_1641349723.png" width="540" />
</p>

---

## What the app does

- **Daily & hourly flight forecasts** — a colour-coded percentage (red/amber/green)
  for each of the next 7 days and for each hour of the current day, showing when
  conditions are right for queens to fly.
- **Location-aware** — uses your device GPS (or last-known position) to fetch local
  weather. You can also pick a place with the built-in Google Places search.
- **Weather-driven model** — the forecast is computed from current + historical
  weather (temperature, humidity, wind, pressure, rain) using a trained
  Random-Forest model (see *The Science* below).
- **Crowd-sourced reports** — users can report a nuptial flight they observed.
  Reports are stored in a backend database (ArangoDB) and shown back to other
  users nearby ("X flights reported near you").
- **Background updates & notifications** — a background-fetch task periodically
  recomputes the percentage and can post a notification when the local flight
  chance is high, or when nearby users report a flight.
- **Home-screen widget** (Android) — a glanceable widget showing today's flight
  percentage, updated by the background task.
- **Map view** — an interactive map (OpenStreetMap tiles via `flutter_map`) where
  you can explore weather layers and reported sightings.
- **Light / dark theme** — follows the system theme.
- **Device-preview** — in debug (non-release) web builds, `device_preview_plus`
  lets you inspect layouts across device sizes.

---

## How it works (data flow)

1. On launch, `main()` initialises Flutter, sets up the home widget, and shows
   the app. Background services are started *after* the first frame (see
   *First-load performance*).
2. `_loadData()` resolves the user's position:
   - fast passive `getLastKnownPosition()`, falling back to an active GPS fix only
     when no cached position exists;
   - or a location chosen via the Google Places picker.
3. `WeatherFetcher` calls OpenWeatherMap for that position:
   - nearest weather station,
   - historical (past-day) weather,
   - current forecast.
4. `Nuptials` scores the weather with two Random-Forest models
   (`nuptialDailyPercentageModel`, `nuptialHourlyPercentageModel`) to produce
   the daily and hourly flight percentages.
5. `ArangoDB` (singleton) loads nearby user-reported flights and (optionally)
   persists new reports.
6. The UI renders the percentages, a 7-day list, an hourly breakdown, and
   the map.

> **API keys required** (see *Getting Started*): an OpenWeatherMap key for
> weather, a Google Maps key for Places search, and an ArangoDB URL/credentials
> for report storage.

---

## The Science

Ant queens mate on the wing in mass "nuptial flights" that are triggered by
specific weather windows (warm, humid, calm, often after rain). The app
originally encoded rules derived from the literature:

* [Weather conditions during nuptial flight of *Manica rubida*](https://antwiki.org/wiki/images/5/50/Depa%2C_L._2006._Weather_conditions_during_nuptial_flight_of_Manica_rubida.pdf)
* [The spatial distribution and environmental triggers of ant mating flights](https://onlinelibrary.wiley.com/doi/epdf/10.1111/ecog.03140)
* [Weather Conditions During Nuptial Flights of Four European Ant Species](https://www.antwiki.org/wiki/images/d/dd/Boomsma%2C_J.J.%2C_Leusink%2C_A._1981._Weather_conditions_during_nuptial_flights_of_four_European_ant_species_.pdf)

Newer versions of the app replace hand-written rules with **data-science models** —
Random-Forest classifiers trained on user-contributed sighting/weather data
(see `lib/models/*.ipynb` notebooks and the generated `lib/models/*.dart`
scoring trees bundled as assets `assets/final_model.json` and
`assets/hour_model.json`).

---

## Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (the project pins
  `sdk: '>=3.9.2 <4.0.0'`).
- An **OpenWeatherMap** API key (free tier) — https://home.openweathermap.org/api_keys
- A **Google Maps** API key (for the Places location picker).
- (Optional) an **ArangoDB** endpoint + credentials for crowd-sourced reports.

### Setup
1. Clone and fetch dependencies:
   ```bash
   git clone https://github.com/bradrushworth/nuptialflight.git
   cd nuptialflight
   flutter pub get
   ```
2. Create `assets/.env` with your keys, e.g.:
   ```dotenv
   OPENWEATHERMAP_API_KEY=<your openweathermap key>
   GOOGLE_API_KEY=<your google maps key>
   ARANGO_URL=https://your-arango-host:8530
   ARANGO_USER=<user>
   ARANGO_PASS=<password>
   ARANGO_DB=<database>
   ```
   (The exact variable names live in `lib/controller/weather_fetcher.dart` and
   `lib/controller/arangodb.dart` — keep them in sync with the code.)
3. Run:
   ```bash
   flutter run            # current platform
   flutter run -d chrome # web
   ```

### Build & release helpers
The following commands are used for packaging (run from the project root):

```bash
# Regenerate launcher/adaptive icons
flutter pub run flutter_launcher_icons:main

# Build an Android App Bundle for Play Store submission
flutter --no-color build appbundle

# (Legacy) sign the app widget automation step
flutter pub run flutter_automation --android-sign
```

### Updating dependencies
```bash
flutter pub upgrade --major-versions   # conservative major bumps
# or
flutter pub upgrade                     # latest within constraints
```
After upgrading, verify with `flutter analyze` (the project currently has **0
errors**; only a few pre-existing `deprecated_member_use` info-hints remain in
`lib/controller/screenshots_other.dart`, `lib/controller/widgets_mobile.dart`,
and `lib/utils.dart`).

---

## First-load performance

The first page shows a spinner until location + weather are fetched. To keep that
fast, the startup path avoids blocking work:

* `initializeService()` (background-fetch config + notification channels) runs
  **after** `runApp()` via `unawaited(...)`, so it never delays the first frame.
* The notification-permission prompt is **not** awaited in `_loadData()` — it is
  fired with `unawaited(...)` so the location/weather network calls start immediately.
* `_getLocation()` does a fast passive `getLastKnownPosition()` first and only
  falls back to an active GPS fix when no cached position exists. This avoids
  fetching the 3 OpenWeatherMap endpoints twice on every launch.
* The active GPS fix uses a 10-second `timeLimit` (was 30s) so a first launch
  with no cached position cannot hang for half a minute.

OpenWeatherMap responses are now cached in `shared_preferences` (keyed by rounded
lat/lon, so a real move invalidates the cache) with per-endpoint TTLs: 30 min for
current/forecast, 24 h for reverse geocoding, 30 days for historical. Repeat
launches and the 15-min background fetch reuse a fresh-enough response, cutting
paid OWM API calls.

---

## Project structure

```
lib/
  main.dart                 # App entry, MyHomePage UI, load/weather flow
  utils.dart                # Shared helpers
  controller/
    weather_fetcher.dart   # OpenWeatherMap calls + location lookup
    nuptials.dart          # Random-Forest scoring of weather -> percentages
    services.dart           # Background-fetch + notifications + widget updates
    arangodb.dart          # ArangoDB singleton: reports & nearby flights
    screenshots_*.dart    # Screenshot/device-preview plumbing (mobile vs web)
    widgets_*.dart         # Platform widget glue (mobile vs web)
  models/
    final_model.dart       # Generated daily-model scoring tree
    hour_model.dart        # Generated hourly-model scoring tree
    *.ipynb               # Training notebooks (Random Forest)
  responses/              # JSON response model classes (OWM, geocoding)
  view/
    map.dart               # Standalone interactive map page
assets/
  .env                    # API keys (not committed)
  final_model.json        # Bundled daily model
  hour_model.json         # Bundled hourly model
test/                     # Unit/widget tests (flutter test)
```

---

## Attribution

Code originally forked from https://github.com/ashgarg143/AppWidgetFlutter

Thanks for the <a href="https://iconscout.com/icons/ant" target="_blank">Ant Icon</a>
by <a href="https://iconscout.com/contributors/vladyslav-severyn">Vladyslav Severyn</a>
on <a href="https://iconscout.com">Iconscout</a>.