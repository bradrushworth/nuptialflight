# fonts/ — bundled icon font

One file: `WingedAnt.ttf`, declared as family `WingedAnt` in the `fonts:`
section of `pubspec.yaml`.

**This is an icon font, not a text font.** It carries a single glyph — a
winged queen-ant silhouette (*Halictus rubicundus*) at codepoint `0xe801` —
exposed as `AppIcons.wingedAnt` in [`lib/view/app_icons.dart`](../lib/view/app_icons.dart)
and used by the Report-flight FAB and the size pickers in `report_sheet.dart`.

All *text* renders in the platform default font. The app ships 13 locales
including Greek, Turkish, Czech and Polish, and relies on the system font for
that coverage — nothing here is involved.

## Rules

- Adding or removing a file means editing `pubspec.yaml` in the same change.
  A font present on disk but undeclared is simply absent at runtime, with no
  error and no build failure.
- Reference glyphs through `AppIcons`, never by writing a raw `IconData` with
  a magic codepoint at the call site.
- If the font is ever regenerated, the codepoint must stay `0xe801` or
  `app_icons.dart` must change with it — a mismatch renders a tofu box rather
  than failing.
- Android home-screen widgets are RemoteViews and cannot use bundled fonts.
  The widget layouts use a drawable instead.
