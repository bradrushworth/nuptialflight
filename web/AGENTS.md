# web/ — web host

Static host files for the Flutter web build: `index.html`, `manifest.json`,
`favicon.*`, `icons/`. Deployed as <https://nuptialflight.app/>.

The web build is a **first-class shipping target**, not a toy: it is what the
in-app "Web App" menu link points at, and `scripts/store/capture_screenshots.py`
captures the store screenshots from it in every locale. A visual regression
here reaches the store listings.

## Running it locally

```bash
flutter run -d web-server --web-port=8123
```

`.claude/launch.json` already defines this as the `web` configuration, so the
Browser pane's `preview_start` can launch it directly.

## Web-only behaviour to know about

- **Location is hardwired in debug web builds.** `weather_fetcher.dart` falls
  back to Canberra (`-35.2809, 149.13`) rather than prompting for geolocation,
  so a debug web session always renders real data. Don't mistake that for a
  location bug.
- **Conditional imports.** `screenshots_other.dart` / `widgets_other.dart`
  are the web halves of `dart.library.io` vs `dart.library.js` pairs. Home
  widgets and background fetch are no-ops on web.
- `screenshots_other.dart` still imports `dart:html` (a known deprecation
  info in `flutter analyze`; migration to `package:web` is outstanding).
- The overflow menu shows the Google Play link on web (`kIsWeb` is part of
  the gate). That is intentional and does not affect App Store compliance,
  which concerns the iOS build and its listing only.

## Bundle size

The three JSON assets in `assets/` (~3.2 MB, roughly a third gzipped)
dominate the download. Check the effect on web before growing a model.
