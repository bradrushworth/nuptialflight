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
   version bump — a code merge without one will not build. NB Codemagic
   matches its skip token loosely, anywhere in the commit message — never
   put the words "skip" and "ci" next to each other in one, in either
   order, even in prose.

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
