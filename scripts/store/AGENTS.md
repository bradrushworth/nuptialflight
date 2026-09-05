# scripts/store/ — store listing generation

| Script | Does |
|---|---|
| `gen_listings.py` | Rewrites **all** listing texts under `store/listings/` |
| `capture_screenshots.py` | Playwright capture of the live web app per locale |
| `capture_sheet_screenshots.py` | Bottom-sheet captures |
| `compose_screenshots.py` | Renders captioned marketing frames |

Output layout and upload instructions: [`store/README.md`](../../store/README.md).

## Everything under `store/listings/` is generated

**Never hand-edit a listing file.** `gen_listings.py` is the source of truth
and will silently overwrite your edit on the next run. Copy changes go in the
`L['<lang>']` dicts inside the script.

Run it from anywhere:

```bash
python scripts/store/gen_listings.py
# -> all limits OK; 13 play locales, 12 ios locales
```

`REPO` is derived from the script's own path, so it works in any checkout or
worktree. (It used to be a hardcoded absolute path into a worktree that no
longer exists — if you see that pattern reappear, it is a bug.)

## The App Store text is NOT the Play text

One `full` string per language feeds both stores, but the App Store copy is
rewritten on the way out.

The Play text markets *"…widgets for Android and iPhone"*. Naming Android got
the app **rejected twice under App Store Guideline 2.3.10** (Accurate
Metadata — no third-party platform references), most recently submission
`7c559f18-3101-4eaf-a83e-a7066c8048e3` on 2026-09-04. So `ios_description()`
swaps that bullet for *"Home Screen and Lock Screen widgets"* — the same
shipped feature (`ios/NuptialWidget` provides systemSmall/systemMedium Home
Screen widgets plus the iOS 16 Lock Screen accessories), in Apple's terms.

Two tables drive it, keyed to the **exact** bullet inside each locale's
`full` text:

- `WIDGETS_PLAY` — the Android-mentioning line as it appears in `full`
- `WIDGETS_IOS` — its App Store replacement

The generator **aborts the whole run** if:

1. neither the Play line nor its replacement is found in a locale's `full`
   (i.e. someone edited the copy without updating the tables), or
2. any App Store text still contains `android`, `google play` or
   `play store`.

That is deliberate. A silent failure here means another rejection and another
review cycle. **If you edit the widgets bullet, update both tables in the
same change.**

## Locale codes differ per store

`LOCALE_MAP` maps a language key to `(play_locale, ios_locale)`. The one that
catches people:

```python
'en': ('en-US', 'en-AU'),   # App Store English is en-AU, not en-US
```

Verified against App Store Connect on 2026-09-05. `fil` has no App Store
locale at all (ASC has no Filipino), so its `ios_locale` is `None` and
Philippine users fall back to the English listing.

## Limits are asserted

Play 30/80/4000, iOS 30/30/170/4000/100. The script prints
`LIMIT VIOLATIONS:` and does not silently truncate. Non-Latin locales run
longer than English — re-run after any copy change.

## Known drift

`fr-FR` and `nl-NL` descriptions live on the App Store differ from the
generated text by one cosmetic phrase each (hand-edits made in the ASC UI
that were never brought back here). Harmless and compliant; the next full
upload will bring them back in line. Don't hand-patch the generated files to
match — fix the copy in `gen_listings.py` if the store wording is preferred.
