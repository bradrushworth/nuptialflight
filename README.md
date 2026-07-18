# Ant Nuptial Flight Predictor

A basic Flutter application with an Android home screen app widget. Works on Android, IOS and Web.

Web App: https://nuptialflight.app/

Ant Nuptial Flight Predictor downloads the weather in your current location and gives you the rough
likelihood that queen ants are flying near you today and for the next week. When the percentage is
high, time to get outside and looking for ants in your local area!

<img src="https://raw.githubusercontent.com/bradrushworth/nuptialflight/master/assets/Screenshot_1641349717.png" height="540" /> <img src="https://raw.githubusercontent.com/bradrushworth/nuptialflight/master/assets/Screenshot_1641349723.png" width="540" />

## The Science

Originally I used these papers to inform the algorithms in the app:

* [Weather conditions during nuptial flight of Manica rubida](https://antwiki.org/wiki/images/5/50/Depa%2C_L._2006._Weather_conditions_during_nuptial_flight_of_Manica_rubida.pdf)
* [The spatial distribution and environmental triggers of ant mating flights](https://onlinelibrary.wiley.com/doi/epdf/10.1111/ecog.03140)
* [Weather Conditions During Nuptial Flights of Four European Ant Species](https://www.antwiki.org/wiki/images/d/dd/Boomsma%2C_J.J.%2C_Leusink%2C_A._1981._Weather_conditions_during_nuptial_flights_of_four_European_ant_species_.pdf)

Newer versions of the app use Data Science algorithms, for example Random Forest over user-contributed data.

## Getting Started

Build in Android Studio.

The following commands were useful:

```
flutter pub pub run flutter_automation --android-sign
flutter packages pub run flutter_launcher_icons:main
flutter --no-color build appbundle
```

Dependency upgrade instruction:

```
flutter pub upgrade --major-versions
```

You'll need to create a file at assets/.env with a line:

```
OPENWEATHERMAP_API_KEY=<your secret key>
```

setting your free https://home.openweathermap.org/api_keys key.

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

There is intentionally **no response caching** yet — every launch repeats the
weather calls. Adding caching (e.g. in `HomeWidget`/`shared_preferences`) would
make repeat launches instant.

## Attribution

Code originally forked from https://github.com/ashgarg143/AppWidgetFlutter

Thanks for the <a href="https://iconscout.com/icons/ant" target="_blank">Ant Icon</a>
by <a href="https://iconscout.com/contributors/vladyslav-severyn">Vladyslav Severyn</a>
on <a href="https://iconscout.com">Iconscout</a>.
