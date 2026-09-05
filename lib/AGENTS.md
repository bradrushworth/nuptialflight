# lib/ — application source

All Dart that ships in the app. Architecture overview:
[docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md). House rules and commands:
[AGENTS.md](../AGENTS.md) at the repo root.

## Layout

| Path | Role | Notes |
|---|---|---|
| `main.dart` | Entry point, `MyHomePage` state, load flow, overflow menu | ~1100 lines; the only stateful orchestrator |
| `utils.dart` | `launchURL`, **`redactUrl`** | `redactUrl` is a security control, not a convenience |
| `controller/` | Data, scoring, interpretation, platform services | The logic layer |
| `models/` | Forest JSON walker + training notebooks | |
| `responses/` | OpenWeatherMap JSON models | |
| `view/` | Widgets | Presentation only, no fetching |
| `l10n/` | ARB sources + generated localizations | 13 locales |

## The one-way dependency rule

`view/` reads from `controller/`, never the reverse, and no widget performs
I/O. `main.dart` owns all state and passes plain values down. When a widget
needs new data, add it to the value the widget already receives rather than
reaching into a controller from the widget.

## Things that bite

- **`main.dart` holds the daily slot arrays.** `_dailyScore` /
  `_dailyPercentage` are `List.filled(8, 0)` — index 0 is today, 1..7 are the
  upcoming-week rows. `_weekDays()` starts at `_weekFirstDay = 1`, so a week
  row `j` is daily slot `j + 1`. Keep using that constant instead of a
  literal `1`.
- **Keep the first frame non-blocking.** Do not add an `await` around
  `runApp()`. Asset parsing (`Nuptials.ensureLoaded`, `FlightIndex.ensureLoaded`)
  is kicked off after the first frame and awaited later in the weather
  pipeline.
- **Every user-visible string is an ARB key.** No hardcoded copy, in any of
  the 13 locales. See `l10n/AGENTS.md`.
- **The app logs with bare `print`, which survives release builds.** Anything
  you log reaches real users' device logs. Never log a URL, credential or raw
  API response — use `redactUrl()` for URLs.
- **`kIsWeb` / `Platform.*` gates matter for store compliance.** The Google
  Play menu link is gated to `kIsWeb || Platform.isAndroid || Platform.isFuchsia`
  precisely so it never renders on iOS; Apple rejects third-party platform
  references (Guideline 2.3.10). Don't ungate it.

## Before you finish

```bash
flutter analyze   # must stay at 0 errors
flutter test
```
