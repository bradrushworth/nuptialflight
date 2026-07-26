# Model retraining findings (2026-07-26)

Findings from retraining the daily nuptial-flight RandomForest against the
live ArangoDB flights data (212,504 rows; 10,127 positives = 4.77%).

## Key finding: production `ccp_alpha` collapses the forest

Reproducing the production training configuration (RandomForest, 64 trees,
`max_features=10`, `min_samples_split=3`, **`ccp_alpha=0.0008`**) on the
current data produces a **degenerate** model: cost-complexity pruning under
the ~4.8% positive-class imbalance prunes **every tree to a single leaf**
(`node_count=1`, feature importances sum to 0). The model predicts the base
rate for every input:

| Model | ROC AUC | Average Precision |
|---|---|---|
| Baseline (production params) | **0.500** | 0.048 |
| Improved config (below) | **0.663** | 0.110 |

## Improved configuration

RF(150 trees, `max_features='sqrt'`, `min_samples_leaf=5`, `max_depth=14`,
`class_weight='balanced_subsample'`, **no `ccp_alpha`**), with engineered
features (15, in this exact order):

```
[lat, lon, hemisphere, sin_doy, cos_doy, day, windSpeed, rain0, humid,
 cloud, press, dewPoint, dew_dep, rain1, rain2]
```

- `sin_doy`/`cos_doy` — cyclical encoding of dayOfYear (replaces `dss`).
- `hemisphere` — 0 = south, 1 = north.
- `dew_dep` — dew-point depression = temp(day) − dewPoint.
- `rain1`/`rain2` — antecedent rain (next-day pop from daily[1]/daily[2]).

Metrics: acc_te 0.895, F1 0.164, **AUC 0.663**, **AP 0.110**. Top
importances: lat .12, lon .117, day .101, dewPoint .088, windSpeed .087,
sin_doy .081, dew_dep .073.

## Export & parity

- `m2cgen.export_to_dart` of the 150-tree forest yields **~82 MB** of Dart —
  not practical to compile/ship. The sklite JSON export is **34 MB** (vs
  ~1 MB for the production asset), so shipping the improved model as-is
  would also bloat the app; a smaller forest (fewer/shallower trees) would
  be needed for production.
- Parity is instead validated via `test/improved_model_parity_test.dart`,
  which walks the sklite JSON (`%TEMP%/final_model_improved.json`) in Dart,
  computing sklearn-style `predict_proba` (mean of per-tree normalised leaf
  values, with inputs cast to **float32** as sklearn does), against
  `%TEMP%/expected.json` from Python. Result: max |dart − python| ≈ 7e-16
  over 200 holdout rows. The test self-skips when the TEMP artifacts are
  absent (e.g. CI).
- Note: sklite's Dart `RandomForestClassifier` only implements majority-vote
  `predict()`; the app's percentages come from the generated `score()` Dart,
  so shipping any retrain still requires an m2cgen Dart export of the final
  (smaller) model.

## Calibration limitation

The m2cgen→Dart pipeline **cannot export a calibrated model**:
`CalibratedClassifierCV` is not a tree ensemble and is not supported by
m2cgen/sklite. If calibrated probabilities are wanted, calibration must be a
post-step in the app (Platt scaling: `p' = sigmoid(a·logit(p)+b)` with the
two constants fitted in Python, or an isotonic lookup table).

## Production compatibility (decision pending)

The improved model is **NOT drop-in**: it uses a different 15-feature order
(no `dss`; adds sin/cos/hemisphere/dew_dep/rain1/rain2). Shipping it requires:
1. rewriting `nuptialDailyPercentageModel`'s `DailyModel.score([...])` call
   in `lib/controller/nuptials.dart` (rain1/rain2 come from daily[1]/[2] pop,
   already in the OWM response);
2. re-pointing the gauge `_PdCurve` feature indices to the new order;
3. updating `test/model_test.dart` / `test/nuptials_test.dart` expectations.

Lower-risk alternative: a **drop-in retrain** with the same 10 production
features, dropping `ccp_alpha` and adding `class_weight='balanced_subsample'`.
Neither candidate has been shipped; `lib/models/final_model.dart` and
`assets/final_model.json` are unchanged pending user approval.

## Pipeline notes

- Training now runs directly from the live DB
  (`https://api.bitbot.com.au:8530`, db `nuptialFlight`, coll `flights`)
  using python-arango with **server-side AQL projection**
  (`RETURN {field…}`) — ~30× faster than `RETURN f`.
- ⚠️ Security: the DB contains a defaced collection ("u have been pwned
  bro…"). Rotate the `notebook` DB user's password and audit for
  unauthorised changes.
- Working artifacts (data cache, models, exports, holdout, scripts) live in
  `%TEMP%` — see `.clinerules` "Resumable work" for the inventory.
