# AGENTS.md — Ant Nuptial Flight Predictor

Guidance for AI coding agents working in this repo — the canonical project
context. Human-facing docs live in [README.md](README.md). Deeper references:

- [docs/model_training_findings.md](docs/model_training_findings.md) — model &
  training history, metrics, reproducibility artifacts
- [docs/database_schema.md](docs/database_schema.md) — ArangoDB collections
  (`flights` / `leadup` / `historical` / `current`)
- [docs/map_shading.md](docs/map_shading.md) — map overlay colour-matrix rationale
- [.clinerules](.clinerules) — Cline-specific tooling quirks (thin pointer here)

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
    weather_fetcher.dart   # location + OpenWeatherMap One Call 4.0 calls,
                           #   splitDaily (lead-up routing), response cache
    scoring.dart           # length-safe hourly/daily model scoring (once/slot)
    nuptials.dart          # model scoring entry points, PD-curve gauges,
                           #   size seasonal prior
    flight_index.dart      # Ant Flight Index (percentiles, bands, odds)
    services.dart          # background fetch, notifications, widget updates
    arangodb.dart          # ArangoDB singleton (reports, nearby flights,
                           #   leadup collection writes)
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
  flight_stats.json        # score percentiles + calibration (see scripts/)
scripts/
  flight_stats_pipeline.py # regenerates flight_stats.json after a retrain
  backfill_leadup.py       # one-time leadup-collection backfill (paid OWM
                           #   calls; idempotent; default 1 rps; --dry-run)
```

## Weather data pipeline (One Call 4.0)

`WeatherFetcher` makes four OpenWeatherMap requests per fresh foreground load
(see the call budget below for caching/costs):

1. **Current Weather 2.5** (`fetchNearestWeatherLocation`) — kept because it
   supplies the place `name` for the location label (4.0 has none).
2. **Hourly timeline** `/data/4.0/onecall/timeline/1h?cnt=48` — the 48-hour
   forecast leg of `fetchWeather()`.
3. **Daily timeline** via **`fetchDailyWeather()`** — the SINGLE
   daily-request implementation (the background service calls it directly).
   Split-and-route: the request is anchored `leadUpDays` (= 2) local days
   into the past with `cnt = leadUpDays + 8` (the 4.0 page cap), so one paid
   call holds the antecedent days AND the 8-day forecast. The pure,
   unit-tested `WeatherFetcher.splitDaily` splits at the **location-local**
   day boundary: past days become the transient `leadUpDaily` field (ML
   training data — see `docs/database_schema.md`), the rest become `daily`,
   so `daily[0]` is always local *today*.
4. **Historical hourly timeline** (`fetchHistoricalWeather`, cached 30 days
   per day+location) — feeds the `historical` collection upload.

Parsing is kind-aware (`OneCallResponse.fromTimelineJson(json, TimelineKind)`)
so empty pages yield empty lists, never null-both; pagination URLs
(`next`/`prev`) are deliberately not modelled — they embed the API key.
Scoring runs through `lib/controller/scoring.dart`: the forest model executes
at most once per slot and short pages zero-fill instead of throwing.

## OpenWeatherMap call budget (paid — One Call by Call)

Only the One Call timeline requests are billed; the 2.5 current-weather and
geocoding calls are free-tier. Per cache-miss:

| Path | 3.0 era | 4.0 (current) | Notes |
|---|---|---|---|
| Foreground forecast | 1 (`/onecall`) | **2** (1h + 1day) | 4.0 splits the endpoints; inherent to the migration |
| Historical | ~1/day (`/timemachine`) | ~1/day (1h timeline) | 30-day cache, keyed per day+location |
| Background refresh | 1 | **1** (`fetchDailyWeather`) | hourly leg deliberately not fetched |
| Lead-up collection | — | **0** | piggybacks the daily call |
| Backfill script | — | 1/row, one-time | operator-run, throttled 1 rps |

Caching (30-min TTL, keys include rounded lat/lon; the daily key is also
day-anchored) bounds all of the above. When touching this area, never add a
paid call to a hot path without updating this table.

## The model contract (do not break this)

The two forests expect features in a **fixed order** that must match the
training notebooks. The only call sites are `nuptialDailyPercentageModel` and
`nuptialHourlyPercentageModel` in `lib/controller/nuptials.dart` — the exact
orders are documented there and in README.md (daily 28 features, hourly 22,
since the 2026-08-30 lead-up retrain; the 7 appended lead-up features are a
contract with `lib/controller/leadup_features.dart` AND
`scripts/train_leadup_experiment.py`).

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
- **Ant Flight Index** (`lib/controller/flight_index.dart` +
  `assets/flight_stats.json`): raw scores are NOT probabilities (tree-vote
  fractions, Brier 0.19 if read as one). The UI therefore presents a
  percentile vs ~219k historical days at the same hemisphere+month, a named
  band (No-fly/Quiet/Watchful/Promising/Prime; Prime starts at the 90th
  percentile, roughly the old "green" threshold), and calibrated "1 in N
  days like this see a reported flight" odds (isotonic fit, cv Brier 0.043).
  Regenerate the stats asset with `python scripts/flight_stats_pipeline.py`
  after every model retrain — it scores the live flights DB with the SHIPPED
  model JSON, so it must run after the new model assets are in place.
  Notifications fire on Prime days only.

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

## Internationalisation (post-2.19.0)

- The app ships in **13 languages**, chosen from where confirmed flight
  reports actually come from (reverse-geocoded from the flights DB):
  en, tr (Turkey is the #2 non-English reporter at 7%), fil, es, fr, de,
  pl, cs, el, pt, nl, id, ms. Unsupported device languages fall back to en.
- Standard Flutter gen_l10n: strings live in **`lib/l10n/app_*.arb`**
  (`app_en.arb` is the template; `l10n.yaml` configures output). Generated
  Dart lands in `lib/l10n/app_localizations*.dart` (checked in). After
  editing ARBs run `flutter gen-l10n` (also runs automatically on build).
- **Every user-visible string must be an ARB key** — no hardcoded literals
  in widgets. Use `context.l10n.<key>` (extension in
  `lib/view/l10n_ext.dart`), which also hosts `bandLabelOf/bandHeadlineOf/
  bandActionOf` for localized Flight Index band copy. The English copies in
  `controller/flight_index.dart` are context-free fallbacks (tests,
  background) — keep them in sync with `app_en.arb`.
- **Background notifications** (`controller/services.dart`) have no widget
  context: they use `backgroundL10n()`, which resolves from
  `PlatformDispatcher.instance.locale` with an English fallback.
- Dates/hours use locale-aware `DateFormat.MMMEd/E/j(localeTag)` — never
  hardcoded patterns like `'ha'`. The l10n delegates preload intl date
  symbols for the active locale.
- When adding a key: add to `app_en.arb` first (with `@key` placeholder
  metadata if parameterised), then add a translation to **all 12** other
  ARBs (gen-l10n falls back to English per-key but emits warnings; keep
  the set complete). Machine-translated is acceptable; keep it short and
  plain, and note that Codemagic builds fail only on missing en keys.
- Widget tests must pass `AppLocalizations.localizationsDelegates` /
  `supportedLocales` to their `MaterialApp` harness or `context.l10n`
  throws.

## Store listings (post-2.19.1)

- `store/` holds the localized Play + App Store listing texts (all 13
  languages, char limits asserted) and `store/README.md` with the upload
  walkthrough. Screenshots are NOT committed (43 MB, regenerable):
  `scripts/store/*.py` capture the **live web app** per locale with
  Playwright (geolocation stubbed to a city whose forecast is currently
  Prime/Promising - check first, marketing shots should show a good day)
  and compose captioned store frames at exact store resolutions
  (iPhone 6.7" 1290x2796, iPad 2048x2732, Play 1080x1920, feature
  graphic 1024x500).
- After UI or copy changes that alter the home screen, regenerate and
  re-upload. App Store Connect has no Filipino locale; `fil` is Play-only.

## Testing

- `flutter test` runs everything. **The ~93 hermetic tests must pass**
  (includes the parser/split/scoring/cache-key suites added with the One
  Call 4.0 migration; `scripts/test_backfill_leadup.py` covers the backfill
  script via `python -m unittest`). Seven tests hit live services and fail
  without real credentials/network: `test/arangodb_test.dart` (live
  ArangoDB), the "Download Fetch" group in `test/weather_test.dart` (live
  OWM One Call, a paid subscription), and the widget smoke test (needs a
  populated `.env`). Don't chase those failures with a placeholder `.env`.
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
   version bump — a code merge without one will not build. NB Codemagic
   matches its skip token loosely, anywhere in the commit message — never
   put the words "skip" and "ci" next to each other in one, in either
   order, even in prose.

## Security notes

- `assets/.env` must never be committed. Be aware that anything shipped in
  the client (OWM key, Google key, Arango credentials) is extractable —
  treat those keys as semi-public and never widen their permissions.
- Credentials live ONLY in the environment now (done 2026-08-30): the app
  reads `ARANGO_PASSWORD` from `assets/.env` (written by the Codemagic
  "Create assets/.env" step from the `nuptialflight` variable group) and
  **degrades gracefully — reporting/nearby-flights disabled — when it is
  absent**; the training notebooks and both `scripts/*.py` read
  `ARANGO_URL/ARANGO_DB_NAME/ARANGO_USER/ARANGO_PASSWORD` env vars. Never
  reintroduce hardcoded fallbacks.
- **Staged credential rotation (2026-08-30):** new builds connect as the DB
  user **`nuptialflight_app`** (rw on flights/historical/current/leadup, no
  admin rights — the in-code default user). The legacy `nuptialflight` user
  stays active only because its old password is compiled into field installs
  as a fallback; disable it once the installed base has upgraded (revisit
  ~2026-12). The `notebook` user was rotated the same day. The historical
  passwords remain in git history — treat them as public. Prefer AQL
  **bind variables** over string interpolation for any new queries; the
  long-term fix is a thin API in front of ArangoDB. The production DB has
  been defaced once before (planted collection removed 2026-08-30) —
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

## Using a Codemagic Mac as a remote workbench

When a task needs macOS/Xcode (project surgery, iOS debugging) and no Mac
is at hand, hold a Codemagic build machine open and drive it over SSH.
Proven 2026-08-22 by adding the NuptialWidget extension target headlessly.

1. **Branch + guard bypass**: push a branch whose HEAD commit message
   contains `[force build]` (an empty commit is fine) so the build guard
   lets it run. Pushes to non-master branches never trigger webhooks —
   you start the build manually.
2. **Keep the machine alive**: in the Workflow Editor, set the (normally
   empty) **Pre-test script** to a sleep, guarded to your branch so a real
   master release during the window is unaffected:
   `if [ "$CM_BRANCH" = "<branch>" ] || [ "$FCI_BRANCH" = "<branch>" ]; then sleep 3300; fi`
   The 60-min max build duration is a hard cap; sleep less than that.
3. **Start the build** from the app page with **Enable SSH/VNC access**
   ticked, selecting your branch. Expand "Explore build machine via SSH or
   VNC client" once it starts. The SSH command is a
   `curl .../ssh_access_script.sh | bash` one-liner; for non-interactive
   use, fetch that script, extract the embedded RSA key and the
   `ssh -p <port> builder@<ip>` details, then run
   `ssh -i key -p <port> builder@<ip> '<command>'` per command. VNC
   details (host:port, password) are also shown if a GUI is truly needed.
4. **On the machine**: repo is at `~/clone` (post-clone script has already
   created `assets/.env`). The workflow's Flutter is
   `/Users/builder/programs/flutter/bin` (NOT the older default on PATH);
   CocoaPods lives in the rbenv shims: use
   `export PATH="$HOME/.rbenv/shims:/Users/builder/programs/flutter/bin:$PATH"`.
   The rbenv rubies (`~/.rbenv/versions/*/bin/ruby`) have the `xcodeproj`
   gem — Xcode project edits that "can't be done by hand" can be scripted
   with it instead of clicking through Xcode.
5. **Bring work home**: `git diff > patch` on the machine, `cat` it over
   SSH to a local file, `git apply`, commit via the normal PR flow. The
   machine's clone cannot push.
6. **Clean up (do not skip)**: cancel the workbench build (stops billing),
   delete the Pre-test keep-alive script in the Workflow Editor, and
   delete the local copy of the SSH key.

Related facts: "Trigger on tag creation" is OFF in the workflow, so tag
pushes never start builds — only pushes to master (and manual starts) do.
Xcode gotcha recorded in `ios/WIDGET_SETUP.md`: the Embed Foundation
Extensions phase must come BEFORE Flutter's "Thin Binary" phase.

**Workbench limitation (learned 2026-08-22):** the App Store Connect API
key never touches the build machine — Codemagic keeps it server-side and
delivers only the distribution certificate (keychain) and pre-matched
provisioning profiles. Apple *portal* operations (registering bundle ids,
App Groups, creating profiles) therefore CANNOT be done from a workbench
session. When a new target/bundle id is added (e.g. the NuptialWidget
extension), someone must register the identifier and its App Group in the
Apple Developer portal first, or add an ASC API key as Codemagic secret
env vars so a build script can run
`app-store-connect fetch-signing-files ... --create`. Until the widget's
bundle id `au.com.bitbot.nuptialflight.NuptialWidget` + App Group
`group.au.com.bitbot.nuptialflight` exist in the portal, every iOS build
fails with "No profiles for ... were found" — which blocks ALL releases.

<!-- BEGIN BEADS INTEGRATION v:1 profile:minimal hash:970c3bf2 -->
## Beads Issue Tracker

This project uses **bd (beads)** for issue tracking. Run `bd prime` to see full workflow context and commands.

### Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --claim  # Claim work
bd close <id>         # Complete work
```

### Rules

- Use `bd` for ALL task tracking — do NOT use TodoWrite, TaskCreate, or markdown TODO lists
- Run `bd prime` for detailed command reference and session close protocol
- Use `bd remember` for persistent knowledge — do NOT use MEMORY.md files

**Architecture in one line:** issues live in a local Dolt DB; sync uses `refs/dolt/data` on your git remote; `.beads/issues.jsonl` is a passive export. See https://github.com/gastownhall/beads/blob/main/docs/SYNC_CONCEPTS.md for details and anti-patterns.

## Agent Context Profiles

The managed Beads block is task-tracking guidance, not permission to override repository, user, or orchestrator instructions.

- **Conservative (default)**: Use `bd` for task tracking. Do not run git commits, git pushes, or Dolt remote sync unless explicitly asked. At handoff, report changed files, validation, and suggested next commands.
- **Minimal**: Keep tool instruction files as pointers to `bd prime`; use the same conservative git policy unless active instructions say otherwise.
- **Team-maintainer**: Only when the repository explicitly opts in, agents may close beads, run quality gates, commit, and push as part of session close. A current "do not commit" or "do not push" instruction still wins.

## Session Completion

This protocol applies when ending a Beads implementation workflow. It is subordinate to explicit user, repository, and orchestrator instructions.

1. **File issues for remaining work** - Create beads for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **Handle git/sync by active profile**:
   ```bash
   # Conservative/minimal/default: report status and proposed commands; wait for approval.
   git status

   # Team-maintainer opt-in only, unless current instructions forbid it:
   git pull --rebase
   bd dolt push
   git push
   git status
   ```
5. **Hand off** - Summarize changes, validation, issue status, and any blocked sync/commit/push step

**Critical rules:**
- Explicit user or orchestrator instructions override this Beads block.
- Do not commit or push without clear authority from the active profile or the current user request.
- If a required sync or push is blocked, stop and report the exact command and error.
<!-- END BEADS INTEGRATION -->

<!-- BEGIN BEADS CODEX SETUP: generated by bd setup codex -->
## Beads Issue Tracker

Use Beads (`bd`) for durable task tracking in repositories that include it. Use the `beads` skill at `.agents/skills/beads/SKILL.md` (project install) or `~/.agents/skills/beads/SKILL.md` (global install) for Beads workflow guidance, then use the `bd` CLI for issue operations.

### Quick Reference

```bash
bd ready                # Find available work
bd show <id>            # View issue details
bd update <id> --claim  # Claim work
bd close <id>           # Complete work
bd prime                # Refresh Beads context
```

### Rules

- Use `bd` for all task tracking; do not create markdown TODO lists.
- Run `bd prime` when Beads context is missing or stale. Codex 0.129.0+ can load Beads context automatically through native hooks; use `/hooks` to inspect or toggle them.
- Keep persistent project memory in Beads via `bd remember`; do not create ad hoc memory files.

**Architecture in one line:** issues live in a local Dolt DB; sync uses `refs/dolt/data` on your git remote; `.beads/issues.jsonl` is a passive export. See https://github.com/gastownhall/beads/blob/main/docs/SYNC_CONCEPTS.md for details and anti-patterns.
<!-- END BEADS CODEX SETUP -->
