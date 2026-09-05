# lib/models/ — the on-device forest runtime

| File | Role |
|---|---|
| `forest_model.dart` | ~80-line pure-Dart RandomForest `predict_proba` walker |
| `*.ipynb` | Training notebooks (historical; the shipped pipeline is `scripts/`) |

## How inference works

The forests are **not** generated Dart. They ship as sklite-format JSON in
`assets/` and `forest_model.dart` walks them at runtime, reproducing
sklearn's `predict_proba`: the mean of per-tree normalised leaf values, with
inputs cast to **float32** exactly as sklearn does.

That float32 cast is not cosmetic — it is what keeps Dart and Python
agreeing to ~1e-14. `test/production_model_parity_test.dart` pins it.

This design replaced m2cgen-generated Dart score trees (~1.09 MB of
generated source) with 0.80 MB of JSON plus a 3 KB walker. The `sklite` pub
dependency was removed because its Dart classifier only implements
majority-vote `predict()`, not probabilities.

## Rules

- **Never hand-edit `assets/*_model.json`.** Regenerate with
  `scripts/export_leadup_models.py`.
- **Feature order is a positional contract.** Nothing validates it at
  runtime; a wrong order yields plausible wrong numbers rather than an error.
  See [docs/ARCHITECTURE.md](../../docs/ARCHITECTURE.md) §4 for the four
  places that must change together.
- `Nuptials.ensureLoaded()` parses the assets once, kicked off after the
  first frame and awaited in the weather pipeline before scoring. Don't move
  it in front of `runApp()`.

## Current models

| | Base | + lead-up | Total | Shape |
|---|---|---|---|---|
| `final_model.json` (daily) | 21 | 7 | **28** | RF 48 trees × 256 leaves, ~1.59 MB |
| `hour_model.json` (hourly) | 15 | 7 | **22** | same |

The hourly model has **no rain and no cloud feature**. This is a real
limitation with UI consequences — see `lib/controller/AGENTS.md`.

## The parity tests self-skip

`production_model_parity_test.dart` and `improved_model_parity_test.dart`
need `%TEMP%/ship_expected.json` and `ship_hour_expected.json`. They skip
cleanly when absent (so CI passes), which also means **a green local run does
not prove parity** unless those fixtures are present. Copy them back before
trusting a model change.
