# ios/ — iOS host project and widget extension

| Path | What |
|---|---|
| `Runner/` | The Flutter host app |
| `NuptialWidget/` | **WidgetKit extension** (Swift) — Home Screen + Lock Screen widgets |
| `Runner.xcodeproj` / `.xcworkspace` | Open the **workspace**, not the project (CocoaPods) |
| `Podfile` | CocoaPods |
| `ci_scripts/` | Codemagic hooks |
| `WIDGET_SETUP.md` | How the widget target was created (already done — reference only) |

## The widget extension

`NuptialWidget.swift` supports:

- `systemSmall`, `systemMedium` — Home Screen
- `accessoryCircular`, `accessoryRectangular`, `accessoryInline` — Lock
  Screen, iOS 16+ only (guarded by `#available`)

The Flutter side pushes data via `home_widget` and reloads timelines by the
kind string, so the target's **Product Name must stay `NuptialWidget`**.

Both targets share the App Group `group.au.com.bitbot.nuptialflight`. If
widget data stops updating, check the App Group entitlement on **both**
targets first — that is almost always the cause.

**Build-phase ordering gotcha:** "Embed Foundation Extensions" must sit
*before* the Flutter "Thin Binary" script phase in Runner's Build Phases, or
the build fails with a dependency cycle.

## App Store compliance lives partly in here

The app has been rejected under **Guideline 2.3.10 — Accurate Metadata** for
mentioning Android. Two things keep it clean:

1. The **listing text** is rewritten for the App Store by
   `scripts/store/gen_listings.py` (see `scripts/store/AGENTS.md`).
2. The **in-app** Google Play link is runtime-gated in `main.dart` to
   `kIsWeb || Platform.isAndroid || Platform.isFuchsia`, so it never renders
   on iOS or iPadOS. Do not ungate it.

Reviewers test on iPad (most recently iPad Air 11-inch M3). Check layouts at
tablet width, not just phone.

The widget's capabilities are also a metadata claim: the App Store
description says "Home Screen and Lock Screen widgets" because this target
genuinely ships both families. If you drop a family, the listing copy must
change too.

## Release

Builds run on Codemagic (`codemagic.yaml`) and upload to TestFlight; the
version comes from `pubspec.yaml`. See the root [AGENTS.md](../AGENTS.md) for
the release process and the Codemagic remote-workbench notes.
