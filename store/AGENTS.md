# store/ — store listing assets (generated)

Full layout, locale table and upload instructions: [`README.md`](README.md).
The generator and its rules: [`scripts/store/AGENTS.md`](../scripts/store/AGENTS.md).

```
listings/play/<locale>/   title · short_description · full_description
listings/ios/<locale>/    name · subtitle · promotional_text · description · keywords
screenshots/play/<locale>/  screenshots/ios/<locale>/
icon/
```

## Everything under `listings/` is generated output

**Do not hand-edit these files.** `scripts/store/gen_listings.py` is the
source of truth and overwrites them on the next run. Copy changes go in the
`L['<lang>']` dicts in that script.

## Three facts that have each cost a review cycle

1. **App Store English is `en-AU`, not `en-US`.** It is the only locale whose
   code differs between the two stores. `listings/ios/en-AU/` is the live
   English App Store copy; `listings/play/en-US/` is the Play one.

2. **The App Store description must not mention Android.** Apple rejected the
   app twice under Guideline 2.3.10. The Play copy legitimately markets
   "widgets for Android and iPhone"; the App Store copy says "Home Screen and
   Lock Screen widgets" instead. The generator enforces this and aborts
   rather than emitting a non-compliant description.

3. **The App Store has no Filipino locale.** `fil` exists for Play only;
   Philippine App Store users see the English listing.

## Uploading

Promotional text can be changed without a review; everything else rides the
next version review. The App Store Connect UI has a known failure mode — a
short browser window makes description textareas save **empty** without
error. Prefer `PATCH /iris/v1/appStoreVersionLocalizations/{id}` with the
`X-Csrf-Itc: itc` header, and **always read the value back from the server
afterwards**. When verifying programmatically, don't add a cache-buster query
param: it makes the API return `200` with an empty `data` array, which turns
an `.every()` check into a vacuous pass.

## Known drift

The live `fr-FR` and `nl-NL` descriptions differ from the generated text by
one cosmetic phrase each — hand-edits made in the ASC UI that were never
brought back here. Compliant and harmless; the next full upload realigns
them. Fix the wording in `gen_listings.py` if the store phrasing is
preferred, rather than patching the generated file.
