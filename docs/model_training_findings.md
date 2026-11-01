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

## Part 6 — hourly calibration table (2026-09-05)

No retrain. `assets/flight_stats.json` gained an `hourly` sibling block, and
the app stopped banding hourly scores with the daily table.

### The problem

`bandFor()` maps a raw score to a band by comparing its **calibrated
probability** against multiples of the base rate. Both the isotonic
calibration and the per-(hemisphere, month) quantiles in `flight_stats.json`
were fitted on **daily** scores only — but `main.dart` also fed the hourly
model's scores through `bandFor()`. The two models score different
distributions, so an hourly 0.55 was being interpreted with thresholds that
describe a daily 0.55.

Raised by the user while questioning whether `minBand()`'s daily cap was
sound. It was a real gap, though not the one the cap was covering.

### The fix

`scripts/flight_stats_pipeline.py` now scores the hourly rows with the
shipped `hour_model.json` — the same 22-feature order as
`nuptialHourlyPercentageModel`, with the hourly cutoffs (`temp < 5`,
`h_windSpeed > 15`, `h_windGust > 20`) and the same clamp — and emits:

```
flight_stats.json
  base_rate / quantiles / calibration      <- daily (unchanged position)
  hourly: { rows, base_rate, quantiles, calibration }
```

`FlightIndex` gained `percentileHourly`, `calibratedProbabilityHourly`,
`oneInNHourly`, `hourlyBaseRate` and `hasHourlyStats`; `bandForHourly()` uses
them. **Assets without the `hourly` key fall back to the daily tables**, so
older builds and hand-written test fixtures keep working.

### Numbers (2026-09-05 run, live DB)

| | rows | base rate | cv Brier (calibrated) | raw-score Brier |
|---|---|---|---|---|
| daily | 224,830 | 0.04685 | 0.04225 | 0.18449 |
| hourly | 219,408 | 0.04651 | 0.04198 | 0.18286 |

Band thresholds in raw score (1× / 2× / 4× base rate):

| | 1× | 2× | 4× |
|---|---|---|---|
| daily (2026-08-30) | 0.46 | 0.57 | 0.76 |
| daily (2026-09-05) | 0.46 | 0.57 | 0.76 |
| **hourly (2026-09-05)** | **0.45** | **0.57** | **0.70** |

Two things worth noting:

- **The daily ladder did not move** despite 2,066 more rows, so no user's
  daily band changes as a result of this rebuild.
- **The hourly ladder is genuinely different at the top**: Prime opens at
  0.70 rather than 0.76. Hours scoring 0.70–0.76 were previously under-banded
  as Promising.

### What this does NOT change

`minBand()` still caps each hour at its day's band. That cap survives because
the **hourly model has no rain or cloud feature at all** — it cannot see a
downpour, so an uncapped hourly band could show green bars in the rain.
Giving the hourly model precipitation features is the prerequisite for
revisiting the cap; the calibration mismatch no longer is.

For the record, the hourly model remains the *stronger* of the two under the
Part 5 protocol (AUC 0.671/0.666 vs 0.660/0.639) — the cap has never been
justified by relative accuracy.

## Part 7 — November 2026 retrain: NOT shipped (2026-11-01)

The owner approved a retrain on the data collected since the 2026-08-30 ship
(Sept-Oct 2026 is the Australian spring flight season). Both models were
retrained with the shipped recipe unchanged (daily 28 features, hourly 22,
same order; RF 48 trees, 256 max leaves, `random_state=42`) and compared with
the shipped assets under the Part 5 protocol. **The candidates are no better
than the shipped models on any honest holdout, so nothing shipped and
`assets/*.json` are untouched.**

### Data (live DB, read-only `notebook` user, 2026-11-01)

| | rows | positives | rate |
|---|---|---|---|
| raw `flights` rows with daily weather | 241,629 | 11,149 | 4.61% |
| after required-field `dropna` | 240,321 | 11,097 | 4.62% |
| **after (install, location, day) dedup** | **149,949** | **10,196** | **6.80%** |
| hourly subset (rows with `hourly[0]`) | 146,570 | 9,889 | 6.75% |
| shipped window (deduped, `dt` < 2026-08-30) | 139,145 | 9,610 | 6.91% |
| **new since the ship (>= 2026-08-30)** | **10,804** | **586** | 5.42% |
| fresh season (>= 2026-09-01) | 10,293 | 547 | 5.31% |
| late season (>= 2026-10-01) | 4,382 | 252 | 5.75% |

The shipped window re-counts at 139,145 against Part 5's 139,193, so there is
no meaningful late-arriving or back-dated data. The new season added only
**+7.8% rows and +6.1% positives** (Sept 5,911 rows / 295 positives, Oct
4,304 / 250), far less than the season's reputation suggested, which is why a
retrain cannot move the models much. Lead-up `prev1` coverage is 60.0% of raw
rows but only **36.3% of raw positives** (see Finding 2). Three rows carry a
`dt` after 2026-11-02 (latest 2026-11-05), presumably device clock skew; they
are harmless but unfiltered.

### How the comparison had to be built

The new data is the only thing a retrain changes, and the shipped assets were
fit on everything up to 2026-08-30. So:

- **Documented holdout (>= 2025-09)** is *not* a fair test of the frozen asset:
  it trained on 2025-09..2026-08-29 and scores 0.76 / 0.13 daily there, which is
  memorisation. Under the protocol the candidate for this holdout is the same
  recipe trained on `dt` < 2025-09, i.e. the shipped recipe itself, so it can
  only show that the recipe still reproduces. It does (tables below).
- **Forward holdouts (the real test).** For a cutoff C, the candidate is
  retrained on every deduped row before C and tested on rows >= C, which the
  frozen shipped asset has also never seen (C >= 2026-09-01). A single cutoff
  of 2026-09-01 is nearly degenerate, because the candidate then has almost
  exactly the shipped training set; so 2026-09-15, 2026-10-01 and 2026-10-15
  were added, where the candidate *has* seen weeks of new-season data the
  shipped model has not. A third arm, the **shipped recipe rebuilt in this
  pipeline on `dt` < 2026-08-30**, separates the effect of the extra data from
  any pipeline difference.
- Candidate and rebuilt metrics are means over 3 forest seeds. Differences
  against the frozen asset carry a paired cluster bootstrap (resampling
  installs, 300 draws), and the whole run was repeated with a second dedup
  seed (7).

### Results (grouped CV by install, dedup; AUC / AP)

Base rates: documented-holdout window 5.1%, fresh season 5.3%, late season
5.75%. AP is only comparable at equal base rate.

| Daily 28f | CV, `dt`<2025-09 pool | CV, all rows | holdout 2025-09..2026-08-29 | fresh >= 2026-09-01 | late >= 2026-10-01 |
|---|---|---|---|---|---|
| Part 5 as documented | 0.660 +-0.015 / 0.147 | n/a | 0.639 / 0.097 | n/a | n/a |
| **Shipped asset, frozen** | n/a | n/a | leaked, not comparable | **0.586 / 0.079** | **0.615 / 0.091** |
| Shipped recipe re-run today (rebuilt) | 0.661 +-0.018 / 0.146 | n/a | 0.640 / 0.097 | 0.584 / 0.081 | 0.611 / 0.096 |
| **Candidate** (all rows before the cutoff) | same recipe | 0.655 +-0.009 / 0.130 | same fit | 0.580 / 0.081 | 0.616 / 0.094 |

| Hourly 22f | CV, `dt`<2025-09 pool | CV, all rows | holdout 2025-09..2026-08-29 | fresh >= 2026-09-01 | late >= 2026-10-01 |
|---|---|---|---|---|---|
| Part 5 as documented | 0.671 +-0.012 / 0.149 | n/a | 0.666 / 0.102 | n/a | n/a |
| **Shipped asset, frozen** | n/a | n/a | leaked, not comparable | **0.635 / 0.088** | **0.670 / 0.111** |
| Shipped recipe re-run today (rebuilt) | 0.672 +-0.016 / 0.148 | n/a | 0.662 / 0.101 | 0.628 / 0.089 | 0.666 / 0.111 |
| **Candidate** (all rows before the cutoff) | same recipe | 0.672 +-0.008 / 0.135 | same fit | 0.629 / 0.088 | 0.674 / 0.106 |

(CV AP on "all rows" is lower than on the pre-2025-09 pool only because that
pool's positive rate is higher, 7.7% vs 6.8%; CV on `dt` < 2026-08-30 is
0.657 / 0.133 daily and 0.672 / 0.136 hourly.)

Candidate minus frozen shipped, paired bootstrap (95% interval), seed-42
candidate, primary dedup seed:

| cutoff (rows / positives) | daily dAUC | daily dAP | hourly dAUC | hourly dAP |
|---|---|---|---|---|
| >= 2026-09-01 (10,293 / 547) | -0.005 [-0.013, +0.002] | +0.002 [-0.002, +0.006] | -0.002 [-0.009, +0.005] | +0.003 [-0.001, +0.009] |
| >= 2026-09-15 (7,521 / 435) | -0.002 [-0.011, +0.006] | +0.002 [-0.004, +0.010] | -0.007 [-0.015, +0.001] | -0.001 [-0.006, +0.003] |
| >= 2026-10-01 (4,382 / 252) | +0.002 [-0.009, +0.014] | +0.006 [-0.002, +0.016] | +0.005 [-0.005, +0.016] | -0.007 [-0.017, +0.002] |
| >= 2026-10-15 (2,205 / 118) | -0.000 [-0.019, +0.020] | +0.008 [-0.005, +0.024] | -0.000 [-0.017, +0.017] | +0.005 [-0.002, +0.014] |

Every interval spans zero and the signs flip between cutoffs. The replicate
dedup seed (7) agrees, with one exception: hourly fresh-season dAUC -0.012
[-0.020, -0.004], which favours the *shipped* model. Candidate minus rebuilt
arm also spans zero almost everywhere; the two hourly-AUC exceptions (one per
dedup seed, at different cutoffs) have opposite signs. CV on the whole
refreshed dataset (0.655 daily / 0.672 hourly) is within one fold-sd of the
documented pool, so CV is not worse.

### Decision: do not ship

The rule was candidate >= shipped on both AUC and AP on the honest holdouts and
not worse in CV. It fails for the daily model (fresh-season AUC 0.580 vs 0.586)
and the hourly model (fresh-season AUC 0.629 vs 0.635; late-season AP 0.106 vs
0.111), and where it does not fail the differences are noise. Two more months of
data (+6% positives) cannot move a 48-tree forest by more than seed noise
(forest-seed sd is 0.001-0.006 AUC here). The shipped models remain current;
the parity fixtures and `flight_stats.json` were not regenerated and
`scripts/export_leadup_models.py` was not run.

What would change this: a materially larger label set, cleaner negatives
(nf-nw6 Tier 2), or the lead-up fix in Finding 2 (bead nf-ofs, owner decision).

### Finding 1 — `dedup()` was non-deterministic, and it moved the hourly metric

`dedup()` kept the survivor with `sort_values('target', ascending=False)`, an
unstable quicksort, so *which negative row survives* depended on the numpy build
and CPU. On numpy 2.5.2 it kept 12,283 different rows from a stable sort, and
the hourly result moved:

| dedup survivor | hourly CV AUC / AP | hourly holdout AUC / AP | daily CV AUC |
|---|---|---|---|
| old `dedup()`, numpy 2.5.2 | 0.690 / 0.158 | 0.681 / 0.107 | 0.660 |
| first row in DB order (stable) | 0.686 / 0.155 | 0.678 / 0.105 | 0.661 |
| **random, fixed seed** (new `dedup()`; 4 seeds) | **0.672-0.673 / 0.148-0.150** | 0.654-0.659 / 0.098-0.100 | 0.660-0.662 |

A DB-order survivor is the *first session of the day*, which lets `hour` tell
negatives from the (usually later) reporting session; at serving time the app is
opened at any hour. The random survivor reproduces the documented 0.671 / 0.666
(Part 5's own run was therefore consistent with a quasi-random survivor). With
the unpatched script this retrain showed a spurious hourly win (fresh-season
+0.013 AUC, interval [+0.003, +0.023]) purely because the candidate was trained
and tested under a different tie-break regime than the frozen asset.
**Fixed** in `scripts/train_leadup_experiment.py` (`DEDUP_SEED`, shuffle then
stable sort); the export script inherits it. The daily model is insensitive.

### Finding 2 — the lead-up gain is partly a coverage artefact

`has_prev1` (the lead-up coverage flag) is correlated with the label for a
reason that is not weather: positives are far less likely to have a prior-day
record (34.1% of positives vs 50.5% of negatives before 2025-09). The flag alone
scores AUC 0.582 (positive when `has_prev1` = 0). That correlation is decaying:
since 2026-08-30 it is 46.8% vs 52.0% (flag-alone AUC 0.526).

Stratified, train < 2025-09, test 2025-09..2026-08-29, daily:

| stratum | n / positives | with lead-up AUC / AP | base features only (21f) |
|---|---|---|---|
| all | 41,921 / 2,157 | 0.640 / 0.097 | 0.621 / 0.082 |
| `has_prev1` = 0 | 20,213 / 1,293 | 0.645 / 0.117 | 0.644 / 0.112 |
| `has_prev1` = 1 | 21,708 / 864 | 0.606 / 0.059 | 0.592 / 0.054 |

The headline +0.019 is mostly the flag separating strata with different base
rates (6.4% vs 4.0%); within `has_prev1` = 1, the stratum the app normally
serves (it supplies `leadUpDaily`; not measured here), the gain is about +0.014
AUC. In the fresh season the base-only recipe scores 0.602 daily / 0.652 hourly
against 0.580 / 0.629 with lead-up (dAUC +0.024 [-0.007, +0.054] daily, +0.020
[-0.003, +0.042] hourly), but the sign reverses on the late-season window
(-0.014 / -0.019, both spanning zero). So this is **not** evidence to drop the
features: it says their value is unproven and that the ~40% no-coverage training
rows, which scarcely occur at runtime, are teaching a label-correlated shortcut.
Diagnostic only; no feature set changed.

### Finding 3 — the shipped models are weaker on the new season than Part 5 said

On rows the frozen assets have never seen (>= 2026-09-01): **daily 0.586 AUC /
0.079 AP, hourly 0.635 / 0.088**, against a 5.3% base rate (AP lift about 1.5x),
versus 0.639 / 0.666 on the Part 5 holdout. The later window (>= 2026-10-01)
looks better (0.615 / 0.670) but holds only 252 positives (AUC standard error
about 0.02). The hourly model is still the stronger of the two. The dip is
concentrated in returning installs: 294 of the 547 fresh-season positives sit on
installs absent from the training window, where daily AUC is 0.627 (shipped) /
0.616 (candidate) and hourly 0.662 / 0.655, against 0.537 / 0.537 daily and
0.604 / 0.608 hourly on installs the models have already seen (shipped /
candidate in each pair).

### Reproduction

Environment: Python 3.13.15, numpy 2.5.2, pandas 3.1.0, scikit-learn 1.9.1.
Pipeline: `train_leadup_experiment.fetch/engineer/add_leadup/dedup` as in the
repo (with the Finding 1 fix). `tle.evaluate()` reproduces Part 5's CV and
holdout within 0.004 (daily 0.661 / 0.640 vs 0.660 / 0.639; hourly 0.672 / 0.662
vs 0.671 / 0.666). The forward-holdout, rebuilt-arm and bootstrap code was
throwaway analysis in a scratch directory and is described above rather than
committed.
