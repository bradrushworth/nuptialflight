# lib/view/ — widgets

Presentation only. No fetching, no scoring, no `DateTime.now()` decisions —
widgets receive plain values from `main.dart` and render them.

| File | Role |
|---|---|
| `verdict.dart` | **`bandColors()` — the single source of truth for band colour**, plus `BandPill` / `VerdictPill` |
| `hero_card.dart` | Today's headline card |
| `hourly_chart.dart` | Next-24h bar chart |
| `week_list.dart` | Upcoming-week rows (tappable → per-day Why sheet) |
| `why_panel.dart` | "Why this forecast?" chips + PD-sparkline sheet |
| `report_sheet.dart` | Report-a-flight bottom sheet |
| `map.dart` | `flutter_map` page with suitability-tinted overlays |
| `l10n_ext.dart` | `context.l10n` shorthand + localized band label helpers |
| `app_icons.dart` | Icon constants |

## Colour rules

**All band colour comes from `bandColors()` in `verdict.dart`.** Do not
special-case a band inside a widget. That exact mistake caused a shipped
regression: `hourly_chart.dart` folded `quiet` into the same neutral grey as
`noFly`, and because ~70% of days are `quiet` *and* hourly bars are capped at
the day's band, the whole chart rendered as one flat grey block most of the
time.

Two rules follow:

1. **Test with a quiet day, not a prime one.** Quiet is the common case. A
   visualisation that only looks right on a good day is broken.
2. **Colour is never the only encoding.** Every pill carries its text label,
   every row a `Semantics` label. This is an accessibility requirement, and
   it is why `BandPill` exists rather than a bare coloured dot.

## Layout constraints that have actually broken

- **Long localized band names.** German "Vielversprechend" is the worst case.
  `week_list.dart` wraps its pill in `FittedBox(fit: BoxFit.scaleDown)` for
  this reason. Any new fixed-width slot needs the same treatment — there is a
  320pt German regression test in `test/ui_widgets_test.dart`.
- **Edge-to-edge on Android.** Scrolling content needs bottom padding that
  clears both the extended FAB and the system navigation bar
  (`MediaQuery.viewPadding.bottom`), or the last rows sit under the nav bar.
  The Why and Report sheets do this too.
- **Minimum 48px tap targets** on list rows.

## The Why sheet is per-day

`showWhySheet` takes an optional `dayLabel`. `main.dart`'s
`_openWhySheet([int day = 0])` reads every figure at slot `day`, so a week
row explains **its own** day. Copy in the sheet must therefore stay
day-neutral — the ARB strings deliberately avoid "today" / "right now"
(`honestyBand`, `sizeSeasonExplainer`, `whyExplainer`, `tagHelps`/`tagHurts`,
`featRainNote`). If you add copy to this sheet, keep it day-agnostic in all
13 locales.

## Widget tests

`test/ui_widgets_test.dart` pumps at a phone viewport so any `RenderFlex`
overflow fails the test. Add a case there for any new fixed-width layout.
