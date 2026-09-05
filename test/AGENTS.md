# test/ — the suite

```bash
flutter test                       # everything
flutter test test/ui_widgets_test.dart
python -m unittest scripts.test_backfill_leadup   # the backfill script
```

**There is no PR-level CI gate.** Run `flutter analyze` (must stay at 0
errors) and `flutter test` yourself before calling work done. Nothing else
will.

`assets/.env` must exist even to analyze or run the hermetic tests — a
placeholder template is in the root [AGENTS.md](../AGENTS.md).

## Map of the suite

| File | Covers |
|---|---|
| `ui_widgets_test.dart` | Every home-screen widget; pumped at a phone viewport |
| `flight_index_test.dart` | Percentiles, calibrated odds, **band anchors** |
| `scoring_test.dart` | Length-safe scoring, zero-fill on short pages |
| `daily_split_test.dart` | `splitDaily` local-day boundary |
| `onecall_v4_parse_test.dart` | Awkward live-API response shapes |
| `cache_key_test.dart` | Cache key construction |
| `leadup_features_test.dart` | The 7 antecedent features |
| `model_test.dart`, `nuptials_test.dart`, `hourly_test.dart` | Feature vectors + day-quality fixtures |
| `size_seasonal_test.dart` | Per-size seasonal prior |
| `report_notification_test.dart` | Notification/report plumbing |
| `redact_url_test.dart` | API-key redaction in logs (a security control) |
| `*_parity_test.dart` | Dart↔Python `predict_proba` agreement |
| `weather_test.dart`, `arangodb_test.dart`, `widget_test.dart` | **Hit live services** |

## Two categories of "passing" that aren't

Both of these make a green run misleading. Know which you are looking at.

1. **Live-service tests.** `arangodb_test.dart`, the "Download Fetch" group
   in `weather_test.dart` (paid OWM subscription) and the widget smoke test
   need real credentials and network. They fail without them. **Don't chase
   those failures with a placeholder `.env`** — you will just mask them.

2. **Self-skipping parity tests.** `production_model_parity_test.dart` and
   `improved_model_parity_test.dart` skip when `%TEMP%/ship_expected.json` /
   `ship_hour_expected.json` are absent, so CI stays green. That means **a
   green local run does not prove model parity.** If you changed anything
   about scoring or the model assets, restore those fixtures first.

## Writing new tests

- **Widget tests pump at 390×844 @3x** (`_phoneSized`) so a `RenderFlex`
  overflow fails the test. Follow that pattern for any new component. For
  anything with a fixed-width slot, add a 320pt case in the longest locale
  (German) — that is the real worst case.
- **Test the common case, not the flattering one.** ~70% of days are
  `quiet`. A chart test built only from `prime` data will pass while the
  shipped UI is unreadable — that is exactly how the all-grey chart bug
  reached users.
- **Pin regressions to their cause.** When fixing a bug, assert the property
  that was violated (e.g. "quiet bars are not the neutral surface colour"),
  not just that the widget renders.
- `FlightIndex.loadFromString()` injects stats without `rootBundle`, so band
  logic is testable hermetically.
