# AGENTS.md — Ant Nuptial Flight Predictor

Guidance for AI coding agents working in this repo. Human-facing docs live in
[README.md](README.md); deep model/training history lives in
[.clinerules](.clinerules) and
[docs/model_training_findings.md](docs/model_training_findings.md).

## What this is

A Flutter app (Android / iOS / Web) that predicts the likelihood of ant
nuptial (mating) flights from local weather, scored by two bundled
Random-Forest models. Users crowd-report sightings to an ArangoDB backend,
and those reports are the training data for the next model retrain.

- Web app: <https://nuptialflight.app/> · Repo:
  <https://github.com/bradrushworth/nuptialflight>
- App id: `au.com.bitbot.nuptialflight` (Play Store + App Store)

## Setup and commands

```bash
flutter pub get
flutter analyze          # must stay at 0 errors (2 known deprecation infos)
flutter test             # see "Testing" for which tests need credentials
flutter run -d chrome    # debug web hardwires a Canberra mock location
```

- **`assets/.env` is required to build at all** (it is a declared asset; the
  bundle fails without it). It is gitignored. For analyze/tests a placeholder
  is fine:

  ```dotenv
  OPENWEATHERMAP_API_KEY=dummy
  GOOGLE_API_KEY=dummy
  ARANGO_URL=https://localhost:8530
  ARANGO_USER=dummy
  ARANGO_PASSWORD=dummy
  ARANGO_DB_NAME=dummy
  ```

- `flutter pub upgrade` has been observed to **hang for many minutes**
  resolving the git dependencies. Kill it and use `flutter pub get` instead
  unless an upgrade was explicitly requested.
- On Windows, `flutter pub get` may print a non-fatal error about
  `windows/flutter/ephemeral/.plugin_symlinks` — safe to ignore.

## Project structure

```
lib/
  main.dart                # entry, MyHomePage state + load flow, overflow menu
  utils.dart               # launchURL helper
  controller/
    weather_fetcher.dart   # location + 3 OpenWeatherMap calls, response cache
    nuptials.dart          # model scoring, PD-curve gauges, size seasonal prior
    services.dart          # background fetch, notifications, widget updates
    arangodb.dart          # ArangoDB singleton (reports, nearby flights)
    units.dart             # metric/imperial display preference
    geo.dart               # syntheticPosition() helper
    install_id.dart        # anonymous per-install UUID
  models/
    forest_model.dart      # RandomForest predict_proba walker (JSON assets)
    *.ipynb                # training notebooks (source of truth for features)
  responses/               # OWM JSON response models
  view/
    verdict.dart           # thresholds + Verdict enum + colours + VerdictPill
    hero_card.dart         # "Flight likely — 64%" hero card
    hourly_chart.dart      # next-24h bar chart
    week_list.dart         # upcoming-week rows
    why_panel.dart         # "Why this forecast?" chips + PD-sparkline sheet
    report_sheet.dart      # report-a-flight bottom sheet
    map.dart               # flutter_map page with suitability-tinted overlays
assets/
  final_model.json         # daily RF model (sklite JSON, 21 features)
  hour_model.json          # hourly RF model (sklite JSON, 14 features)
```

## The model contract (do not break this)

The two forests expect features in a **fixed order** that must match the
training notebooks. The only call sites are `nuptialDailyPercentageModel` and
`nuptialHourlyPercentageModel` in `lib/controller/nuptials.dart` — the exact
orders are documented there, in README.md, and in `.clinerules`.

- Never hand-edit `assets/*_model.json` or restructure
  `lib/models/forest_model.dart` maths; regenerate the JSON from the
  notebooks instead.
- If a model is retrained with different features, update the call site AND
  `test/nuptials_test.dart`, `test/hourly_test.dart`, `test/model_test.dart`,
  `test/production_model_parity_test.dart` together. A mismatched order
  produces silently wrong predictions.
- The per-attribute gauge functions (`temperatureContribution` etc.) are
  partial-dependence curves derived from the daily model, not hand-tuned
  distributions. They feed the "Why this forecast?" sheet and the map
  overlay tinting; features the model ignores resolve to a neutral 0.5.

## UI conventions (post-2.17.0 Material 3 overhaul)

- **Material 3, stable eucalypt-green seed** (`kSeedColor` in main.dart).
  Verdict colours (green/amber/red) appear only on data — hero card, pills,
  chart bars — never on the app chrome. Do not reintroduce the old
  whole-app retint.
- Verdict thresholds and labels live in **`lib/view/verdict.dart`** (single
  source of truth; `main.dart` re-exports them for `services.dart`).
- Colour is never the only encoding: verdict pills carry text labels, and
  interactive widgets carry `Semantics` labels. Keep touch targets >= 44px
  and do not suppress user font scaling.
- Units: OWM is always queried in **metric**; `Units` (controller/units.dart)
  converts at display time only. Never feed converted values to the models.
- Keep first-frame startup non-blocking: `initializeService()`, the
  notification-permission request, and `Nuptials.ensureLoaded()` are started
  `unawaited` around `runApp()` — do not add `await`s there.

## Testing

- `flutter test` runs everything. **62 tests are hermetic and must pass.**
  Four tests hit live services and fail without real credentials/network:
  `test/arangodb_test.dart` (live ArangoDB) and three "Download Fetch" tests
  in `test/weather_test.dart` (live OWM One Call, a paid subscription).
  Don't chase those failures when running with a placeholder `.env`.
- The two parity tests self-skip unless `%TEMP%/ship_expected.json` /
  `ship_hour_expected.json` fixtures exist (regenerated by the notebook
  pipeline).
- New UI widgets get widget tests in `test/ui_widgets_test.dart`, pumped at
  a phone-sized viewport (390x844 @3x) so RenderFlex overflows fail the
  test. Follow that pattern for new components.
- There is **no PR-level CI gate** — run `flutter analyze` + `flutter test`
  yourself before declaring work done or merging.

## Release process

1. Bump `version:` in `pubspec.yaml` (semver + incremented build number,
   e.g. `2.17.0+142`) and commit.
2. Merge to `master` (repo convention: merge commits, via PR).
3. Tag `vX.Y.Z` on the merge commit, push the tag, and create a GitHub
   release with user-facing notes (convention started at `v2.17.0`).
4. **Codemagic** (configured outside the repo; mirrored in
   `codemagic.yaml`) builds the store artefacts and deploys the web app.
   Deployment can be verified externally:
   `curl https://nuptialflight.app/version.json` reports the live version.
5. **Build guard:** pushes to `master` only produce a full build when the
   `pubspec.yaml` version changed since the last successful build, or that
   build failed; otherwise the build self-cancels in seconds. Force a build
   with `[force build]` in the commit message; skip entirely with the
   native `[skip ci]`. Consequence: shipping anything to users REQUIRES a
   version bump — a code merge without one will not build. NB the skip
   marker is matched anywhere in the commit message, so never mention the
   bracketed skip token in prose.

## Security notes

- `assets/.env` must never be committed. Be aware that anything shipped in
  the client (OWM key, Google key, Arango credentials) is extractable —
  treat those keys as semi-public and never widen their permissions.
- Known review findings (see git history / PR #9 discussion): hardcoded
  credential fallbacks in `arangodb.dart`/`main.dart` should be removed once
  the credentials are rotated; prefer AQL **bind variables** over string
  interpolation for any new queries; the long-term fix is a thin API in
  front of ArangoDB. The production DB has been defaced once before —
  assume hostile traffic.
- Reports are keyed by an anonymous per-install UUID
  (`controller/install_id.dart`). Do not add device identifiers or other
  fingerprinting.

## Misc gotchas

- `services.dart` imports `main.dart` for the verdict thresholds; keep the
  re-export in `main.dart` intact if you move things.
- Conditional imports (`widgets_mobile.dart` / `widgets_other.dart`,
  `screenshots_*.dart`) provide the mobile/web splits — both files must keep
  identical public signatures.
- Several dependencies are personal git forks (see `pubspec.yaml`); version
  bumps there require editing the fork, not just the constraint.
- `debugPrint`/`developer.log` over `print`, and never log URLs containing
  `appid=` (the OWM key).
