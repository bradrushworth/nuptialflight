# Store listing assets

Modernised Google Play + App Store listing material in the app's 13 languages,
generated 2026-08-22 against v2.19.x (Ant Flight Index + i18n releases).
Screenshots are real captures of the live web app (nuptialflight.app) with
geolocation pinned to Manila — a genuine Prime day at capture time — composed
onto captioned marketing frames.

## Layout

```
listings/play/<locale>/   title.txt (<=30) - short_description.txt (<=80) - full_description.txt (<=4000)
listings/ios/<locale>/    name.txt (<=30) - subtitle.txt (<=30) - promotional_text.txt (<=170)
                          description.txt (<=4000) - keywords.txt (<=100)
screenshots/play/<locale>/ 01_home 02_why 03_report 04_dark (1080x1920) + feature_graphic.png (1024x500)
screenshots/ios/<locale>/  01..04 (1290x2796, iPhone 6.7") + ipad_01_home.png (2048x2732, iPad 12.9")
```

All character limits are asserted by the generator; every file is within them.

## Locales

Play (13): en-US, tr-TR, fil, es-ES, fr-FR, de-DE, pl-PL, cs-CZ, el-GR, pt-BR, nl-NL, id, ms
App Store (12): en-AU, tr, es-ES, fr-FR, de-DE, pl, cs, el, pt-BR, nl-NL, id, ms —
the same languages minus `fil` (App Store Connect has no Filipino locale;
Philippine users fall back to the English listing).

**English on the App Store is `en-AU`, not `en-US`** — verified against App
Store Connect on 2026-09-05. That is the only locale whose code differs
between the two stores, and it is why `LOCALE_MAP` in `gen_listings.py` maps
`'en' -> ('en-US', 'en-AU')`.

### The App Store description is NOT the Play description

`gen_listings.py` writes one `full` text to Play, but rewrites the widgets
bullet before writing the App Store copy. The Play text markets
"…widgets for Android and iPhone"; naming Android got the app **rejected
twice under Guideline 2.3.10** (Accurate Metadata — no third-party platform
references), most recently submission `7c559f18-3101-4eaf-a83e-a7066c8048e3`
on 2026-09-04. The App Store text says "Home Screen and Lock Screen widgets"
instead — the same shipped feature (`ios/NuptialWidget` provides
systemSmall/systemMedium Home Screen widgets plus the iOS 16 Lock Screen
accessories), described in Apple's terms.

The swap lives in `WIDGETS_PLAY` / `WIDGETS_IOS` + `ios_description()`. Both
are keyed to the exact bullet inside each locale's `full` text, and the
generator **aborts** if a copy edit breaks the match or if any App Store text
still contains "android" / "google play" / "play store". If you edit the
widgets bullet, update those two tables in the same change.

## Uploading

**Google Play Console** -> Grow users -> Store presence -> Main store listing:
add each language ("Manage translations"), paste the three texts, upload the
4 phone screenshots and the feature graphic per language.

**App Store Connect** -> App -> the current version -> localizations (+ button):
paste name/subtitle/promo/description/keywords, upload the 4 iPhone 6.7"
screenshots and the iPad screenshot per language. Promotional text can be
changed without a review; the rest rides the next version review.

## Regenerating

`scripts/store/capture_screenshots.py` captures the live site in every locale
via Playwright (`pip install playwright`, uses the installed Chrome). Pick a
location with a Prime/Promising forecast first (edit the lat/lon in the
geolocation stub). `scripts/store/compose_screenshots.py` renders the captioned
frames; `scripts/store/gen_listings.py` rewrites the listing texts. Raw
captures land in `store/raw/` (gitignored).

## App icon

`store/icon/play_icon_512.png` is the Google Play store-listing icon (512x512,
opaque PNG), generated from `assets/icon/icon.png` which in turn comes from
`scripts/icon/gen_icon.py`. Regenerate with:

```
python scripts/icon/gen_icon.py
python -c "from PIL import Image; Image.open('assets/icon/icon.png').convert('RGB').resize((512,512), Image.LANCZOS).save('store/icon/play_icon_512.png')"
```

Play's store-listing icon is a single app-wide asset: the per-language
Graphics pages display it, but changing it on the default listing changes it
everywhere (the Publishing overview records one "Change app icon" item, not
one per locale). The iOS App Store icon is not uploaded at all - it is read
from the app binary, so it ships with the build.
