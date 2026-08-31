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
  `%TEMP%` — see the "Reproducibility artifacts" appendix at the end of this
  file for the inventory.

## SHIPPED (2026-07-26, later the same day)

User approved shipping. What actually shipped (version 2.15.0+137):

- **Compact daily model**: RF(24 trees, `max_features='sqrt'`,
  `max_leaf_nodes=128`, `min_samples_leaf=5`,
  `class_weight='balanced_subsample'`, `random_state=42`), same 15 features.
  **AUC 0.6430, AP 0.0870** (vs 0.663/0.110 for the impractical 150-tree
  version, and 0.500/0.048 for the degenerate old config). 398 KB JSON.
- **Compact hourly model** (same recipe) on 207,101 hourly rows (4.73%
  positives): **AUC 0.6676, AP 0.0927**. 12 features `[lat, lon, hemisphere,
  sin_doy, cos_doy, hour, temp, windSpeed, humid, press, dewPoint, dew_dep]`
  (still no rain/cloud; hour = UTC 0-23). 397 KB JSON.
- **JSON-only runtime**: the m2cgen-generated Dart score trees were RETIRED.
  `lib/models/forest_model.dart` (hand-written, pure-Dart predict_proba
  tree-walker) scores the bundled sklite JSON assets directly. Parity with
  Python `predict_proba`: max |err| ~2e-14 (daily) / ~1e-14 (hourly), see
  `test/production_model_parity_test.dart`. The `sklite` pub dependency was
  removed (its Dart classifier only implements majority-vote `predict()`).
- `Nuptials.ensureLoaded()` parses the assets once; it is kicked off right
  after `runApp()` and awaited in the weather pipeline before scoring.
- Size story: old shipped artifacts ~1.09 MB of generated Dart + 0.30 MB
  JSON; new: 0.80 MB JSON + a 3 KB walker, with both models retrained and
  no longer degenerate.
- Test fixtures in `nuptials_test.dart` were rebuilt around the model's
  partial-dependence optima (warm ~30 C, calm ~1.5 m/s, ~67% humidity,
  overcast, high pressure ~1035 hPa); model scores now rank
  Perfect .60 > Great .55 > Ordinary .50 > Bad .41 > Worst .01.
- The training notebooks (`lib/models/*.ipynb`) were rewritten to the new
  pipeline (projected AQL fetch, engineered features, compact RF config,
  sklite export + parity fixtures); autosklearn is no longer used.

## Part 4 — unused-field retrain, size prior, rain relabel (2026-07-26, v2.16.0+139)

Three user-requested changes shipped together.

### 1. Per-size seasonal prior (UX)
The `flights` collection stores a queen `size` (small/medium/large) on every
confirmed sighting — 10,127 sized positives (small 5,036 / medium 2,930 /
large 2,159; 2 null). Analysis:
- Size classes overlap almost completely on *weather* (mean temp 23.8-24.4C,
  wind ~5.1, humidity ~55 across all three) — so three separate weather models
  would just thin the data for no gain.
- They differ in *seasonal timing* (NH: small peaks Jul, medium Jun-Jul, large
  earlier/broader May-Jun; SH offset ~6 months).
Therefore we ship a **seasonal prior**, not separate forests:
`sizeSeasonalMultiplier()` / `sizeSeasonalPercentages()` in `nuptials.dart`
(per-hemisphere monthly weight tables, 3-month smoothed, peak-normalised to
1.0), surfaced as a likelihood line on the main screen under the date/weather text ("Nuptial flight likely today - most likely small (~10mm) species").

### 2. Retrain both models with previously-unused DB fields
Both retrains keep RF(`max_features=sqrt`, `min_samples_leaf=5`,
`class_weight=balanced_subsample`, `random_state=42`) but grow to **48 trees /
256 leaves** (the richer feature set benefits from more capacity; assets ~1.5 MB
each, ~500 KB gzipped for web — acceptable).

- **Daily**: 15 -> **21 features**, appending `uvi`, `windGust`, `rainMm`
  (rain amount, not just pop), `daylength` (from sunrise/sunset), and
  `moonSin`/`moonCos` (cyclical moon phase). **AUC 0.643 -> 0.654, AP
  0.087 -> 0.097.** New-field importances: daylength .065, windGust .057,
  uvi .05, moon ~.04, rainMm .015. The first 15 features keep their order
  (new ones appended 15-20) so the PD-gauge indices are unchanged.
- **Hourly**: 12 -> **14 features**, appending `uvi` + `windGust`.
  **AUC 0.668 -> 0.670, AP 0.093 -> 0.097.** Visibility was tested and
  DROPPED (importance 0.004 = noise).

### 3. rain1/rain2 relabelled popNext1/popNext2 (honesty fix)
Verified `flights.weather.daily` is **today + 7-day forecast** (daily[0] =
report day, daily[-1] = +7d), with NO past days stored anywhere. The old
`rain1`/`rain2` (from daily[1]/[2].pop) are therefore *forward-looking forecast
pop*, NOT antecedent rain. Renamed to `popNext1`/`popNext2` everywhere. True
antecedent / "lead-up change" features (first warm day after rain, pressure
trend, days-since-rain) would require an **OWM timemachine backfill** of each
report's prior days — not stored in the DB, so documented here as the main
future accuracy lever, NOT done in this release.

### Verify / reproduce
Parity: `test/production_model_parity_test.dart` max |err| ~8e-15 (daily) /
~6e-15 (hourly). TEMP artifacts (random_state=42): `fetch_chunk2.py` ->
`prep2.py` -> `ship2.py` (daily, `df2.pkl`, `features2.json`,
`ship_model2.*`, `ship_expected2.json`); `fetch_hourly_chunk2.py` ->
`hourly_final2.py` (hourly). Day-quality fixtures + gauges recalibrated;
all model/nuptials/hourly/size/parity tests pass; `flutter analyze` = 4
pre-existing infos only.
## Appendix — Reproducibility artifacts (`%TEMP%`)

Working artifacts may be wiped between sessions. Deterministic re-create
(random_state=42):

- Daily: `fetch_chunk.py` (resumable projected AQL) -> `prep.py` -> `df.pkl`
  (212,504 rows) -> `ship_train.py` -> `ship_model.pkl/.json` +
  `ship_expected.json` (200-row float32 parity fixture) + `features.json`.
  Part-4 (21-feature) variants: `fetch_chunk2.py` -> `prep2.py` -> `ship2.py`
  (`df2.pkl`, `features2.json`, `ship_model2.*`, `ship_expected2.json`).
- Hourly: `fetch_hourly_chunk.py` (loop until 0) -> `hourly_train.py` ->
  `hourly_df.pkl` -> `hourly_ship.py` -> `ship_hour_model.pkl/.json` +
  `ship_hour_expected.json` + `hourly_features.json`; part-4 variants
  `fetch_hourly_chunk2.py` -> `hourly_final2.py`.
- Analysis: `pd_sweep.py` (per-feature partial-dependence optima used for
  the gauges, test fixtures, AND the map shading — see
  `docs/map_shading.md`), `recal.py`/`recal2.py`/`refix.py` (recalibrate
  test expectations), `calc_expect.py`.
- The parity tests self-skip when `%TEMP%/ship_expected.json` /
  `ship_hour_expected.json` are absent (CI-safe). Copy those two files back
  into `%TEMP%` before running them.

## Part 5 — lead-up features + solar hour + honest evaluation (2026-08-30, v2.27.0+157)

Shipped after the PR #35 review cycle. Three changes landed together:

### 1. Honest evaluation protocol (the re-baseline)
`scripts/train_leadup_experiment.py` replaces random `train_test_split` with
**GroupKFold(5) by install** + per (install, location, day) **dedup**
(222,757 -> 139,193 rows; positive rate 4.8% -> 6.9%) + a temporal holdout
(>= 2025-09). Under this protocol the part-4 models re-baseline at **daily
AUC 0.627** and **hourly 0.640** — the previously reported 0.654/0.670 were
inflated by near-duplicate rows straddling the random split.

### 2. Lead-up (antecedent weather) features — the "main accuracy lever"
7 features appended to both models: `prev1_rain, prev2_rain, dpress1,
dtemp1, days_since_rain (censored at 2), warm_dry_after_rain, has_prev1`
(contract: `lib/controller/leadup_features.dart` <->
`train_leadup_experiment.py::add_leadup`). Training derives them UNIFORMLY
for positives and negatives via a flights self-join (same install — else
same ~11 km cell — on day-1/day-2; coverage 59.8%); the positives-only
backfilled `leadup` collection is used only to VALIDATE the derivation
(993 overlaps: pressure MAE 1.17 hPa, rain MAE 2.44 mm). At runtime the
features come from the split-and-route `leadUpDaily` slice at zero extra
API calls; forecast days use the forecast days before them.

### 3. Local solar hour (hourly model)
UTC `hour` replaced by cyclical `solar_sin/solar_cos` where
solar = (utc_hour + lon/15) mod 24.

### Results (grouped 5-fold CV, temporal holdout in parentheses)
| Model | AUC | AP |
|---|---|---|
| daily 21f re-baseline | 0.627 ±0.008 (0.622) | 0.129 (0.082) |
| **daily 28f shipped** | **0.660 ±0.015 (0.639)** | **0.147 (0.097)** |
| hourly 14f re-baseline | 0.640 ±0.009 (0.651) | 0.132 (0.092) |
| hourly +solar only | 0.645 ±0.008 (0.658) | 0.135 (0.093) |
| **hourly 22f shipped** | **0.671 ±0.012 (0.666)** | **0.149 (0.102)** |

### Shipping notes
- Assets exported by `scripts/export_leadup_models.py` (hand-rolled
  sklite-format JSON; RF 48x256 as before; ~1.59 MB each). Parity fixtures
  (`%TEMP%/ship_expected.json`, `ship_hour_expected.json`) verified by
  `test/production_model_parity_test.dart`.
- `flight_stats.json` regenerated with the 28-feature scores (quantiles +
  isotonic recalibrated); band anchors in `test/flight_index_test.dart`
  re-pinned.
- Gauge/day-quality fixtures recalibrated; ordering preserved
  (Perfect .61 > Great .59 > Ordinary .49 > Bad .44 > Worst .01).
- The `leadup` DB collection backfill (positives-only, idempotent) feeds
  FUTURE retrains with real API antecedents; ~4.1k/10.1k rows done at time
  of shipping (paused at the OWM daily call cap; rerun resumes free).
