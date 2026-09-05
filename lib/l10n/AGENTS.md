# lib/l10n/ — internationalisation

13 locales: **en, cs, de, el, es, fil, fr, id, ms, nl, pl, pt, tr**.

| Files | Status |
|---|---|
| `app_*.arb` | **Source.** Edit these. |
| `app_localizations*.dart` | **Generated.** Never hand-edit. |

`app_en.arb` is the template (`l10n.yaml`). Regenerate with:

```bash
flutter gen-l10n
```

Both the `.arb` and the generated `.dart` files are committed, so a change is
only complete when you have regenerated **and** staged both.

## The rule

**Every user-visible string is an ARB key, in all 13 locales.** No hardcoded
copy anywhere in `lib/`. Adding a key to `app_en.arb` alone leaves 12 locales
falling back to English.

## Writing copy that survives

- **Keep it day-neutral where it can be reused.** The "Why this forecast?"
  sheet is reachable per-day from the upcoming-week list, so its strings must
  not say "today" or "right now". `honestyBand`, `sizeSeasonExplainer`,
  `whyExplainer`, `tagHelps`, `tagHurts` and `featRainNote` were all reworded
  for exactly this reason — don't reintroduce a temporal subject.
- **Avoid putting an inserted value in a grammatical role.** Inflected
  languages (cs, pl, el, tr) make "{day} is better than…" awkward to
  translate well. Prefer a construction where the placeholder is a value, not
  a subject.
- **Mind the length.** German is the worst case for UI fit
  ("Vielversprechend"). `week_list.dart` uses `FittedBox(scaleDown)` and
  there is a 320pt German overflow test in `test/ui_widgets_test.dart`.
- **Brand words pass through.** "Android", "iOS", "Web App" are not
  translated — `_choiceTitle` in `main.dart` maps menu entries by their
  stable English title.

## Placeholders

Declared in the `@key` metadata object, e.g.

```json
"honestyBand": "Ant Flight Index: {band} - better than {percentile}% of days...",
"@honestyBand": {"placeholders": {"band": {"type": "String"}, "percentile": {"type": "int"}}}
```

The metadata only needs to live in `app_en.arb`; translations carry the bare
string.

## Locale codes differ from the store listings

App copy uses plain language codes (`en`, `pt`, `nl`). Store listings use
store-specific codes, and they are **not** the same across stores — App Store
English is `en-AU` while Play is `en-US`. See `store/README.md`.
