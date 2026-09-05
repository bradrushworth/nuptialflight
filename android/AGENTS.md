# android/ — Android host project

| Path | What |
|---|---|
| `app/src/main/kotlin/au/com/bitbot/nuptialflight/MainActivity.kt` | Flutter host activity |
| `…/AppWidgetProvider.kt` | Home-screen widget provider |
| `…/FlightTileService.kt` | **Quick-settings tile** |
| `app/src/main/res/layout/widget_layout*.xml` | Widget layouts (normal + small) |
| `app/src/main/AndroidManifest.xml` | Declares the tile service + widget receivers |
| `app/build.gradle`, `gradle/` | Build config |

## Three background surfaces, one source of truth

The widget, the quick-settings tile and Prime-day notifications all display
the same Flight Index band. Dart pushes the values (`home_widget` /
`controller/services.dart` and `widgets_mobile.dart`); the Kotlin side only
renders what it is given.

Because they all derive from `bandFor()` / `bandLabel()`, **a change to band
thresholds silently changes when users get notified and what their widget
says.** Treat threshold changes as a product change, not a refactor.

## Edge-to-edge

The app draws under the system navigation bar. Any scrolling Flutter surface
needs bottom padding that clears both the extended FAB and
`MediaQuery.viewPadding.bottom`, or content rests underneath the nav bar.
This has regressed before on the home page and both bottom sheets.

## Notification permission

Android 13+ requires a runtime notification permission. It is requested in
`main.dart` via `_requestNotificationPermission()`, which **never rethrows** —
a refused or unavailable prompt must not break a page that has already
loaded.

## Gotchas

- `registerBackgroundCallback` is deprecated (a known `flutter analyze` info,
  not an error). Migrating to `registerInteractivityCallback` is outstanding.
- Widget layouts are RemoteViews — the usual restricted subset of views and
  no custom fonts.
- Play Store listing text lives in `store/listings/play/` and **may** mention
  Android; only the App Store copy must not. See `scripts/store/AGENTS.md`.
