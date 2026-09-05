"""Builds assets/flight_stats.json (rerun after every model retrain): per-(hemisphere, month) score quantiles
and an isotonic score->probability calibration table, from the live flights
DB scored with the SHIPPED daily model (assets/final_model.json), replicating
lib/controller/nuptials.dart nuptialDailyPercentageModel exactly (including
hard cutoffs and clamping) so distributions match what users see."""
import json, math, sys
from datetime import datetime, timezone

import numpy as np
import pandas as pd
from arango import ArangoClient

import os
REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# --- 1. fetch (same projection as the training notebook) ---
# Credentials come from the environment only (see AGENTS.md security notes;
# the previously committed password must be treated as rotated):
#   set ARANGO_PASSWORD=...   (required; the training/'notebook' user's)
#   set ARANGO_USER=notebook  (optional overrides below)
ARANGO_URL = os.environ.get('ARANGO_URL', 'https://api.bitbot.com.au:8530')
ARANGO_DB = os.environ.get('ARANGO_DB_NAME', 'nuptialFlight')
ARANGO_USER = os.environ.get('ARANGO_USER', 'notebook')
ARANGO_PASSWORD = os.environ.get('ARANGO_PASSWORD')
if not ARANGO_PASSWORD:
    sys.exit('ARANGO_PASSWORD env var is required (training DB credential)')
client = ArangoClient(hosts=ARANGO_URL)
db = client.db(ARANGO_DB, username=ARANGO_USER, password=ARANGO_PASSWORD)
# Feature engineering is shared verbatim with the training pipeline (2026-08-30
# retrain: 21 base features + 7 derived lead-up features) so the stats reflect
# exactly what the shipped 28-feature model sees.
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import train_leadup_experiment as tle  # noqa: E402

print('fetching...', flush=True)
df = tle.engineer(tle.fetch(db))
df, _cov = tle.add_leadup(df)
# NB deliberately NOT deduped: percentiles are "vs historical days as
# recorded", matching the app's original stats semantics.
df['month'] = pd.to_datetime(df['dt'], unit='s', utc=True).dt.month
temp = df['day'].to_numpy(float)
wind = df['windSpeed'].to_numpy(float)
gust = df['windGust'].to_numpy(float)
hemi = df['hemisphere'].to_numpy(float)

X = df[tle.DAILY_BASE + tle.LEADUP_FEATS].astype(float).to_numpy()

# --- 3. score with the shipped forests (vectorised tree walk) ---
def score_all(X, model):
    n = X.shape[0]
    acc = np.zeros(n)
    for t in model['dtrees']:
        cl = np.asarray(t['children_left']); cr = np.asarray(t['children_right'])
        th = np.asarray(t['threshold'], float); fe = np.asarray(t['feature'])
        val = np.asarray(t['value'], float)
        node = np.zeros(n, dtype=int)
        active = fe[node] != -2
        while active.any():
            idx = np.where(active)[0]
            f = fe[node[idx]]
            go_left = X[idx, f] <= th[node[idx]]
            node[idx] = np.where(go_left, cl[node[idx]], cr[node[idx]])
            active = fe[node] != -2
        v = val[node]
        acc += v[:, 1] / v.sum(axis=1)
    return acc / len(model['dtrees'])


daily_model = json.load(open(f"{REPO}/assets/final_model.json"))

print('scoring...', flush=True)
raw = score_all(X, daily_model)
# runtime cutoffs + clamp, as in nuptialDailyPercentageModel
score = np.clip(raw, 0.01, 0.99)
score = np.where((temp < 5) | (wind > 15) | (gust > 20), 0.01, score)
df['score'] = score
print('scored. mean', round(float(score.mean()), 4), flush=True)

# --- 4. per-(hemisphere, month) quantiles ---
qs = np.arange(0, 101, 5) / 100.0
quantiles = {'n': {}, 's': {}}
for h, key in [(1.0, 'n'), (0.0, 's')]:
    for m in range(1, 13):
        sel = df[(hemi == h) & (df['month'] == m)]['score']
        if len(sel) >= 200:
            quantiles[key][str(m)] = [round(float(v), 4) for v in np.quantile(sel, qs)]
        else:
            quantiles[key][str(m)] = None
    # hemisphere-wide fallback for sparse months
    allq = [round(float(v), 4) for v in np.quantile(df[hemi == h]['score'], qs)]
    quantiles[key]['all'] = allq
    for m in range(1, 13):
        if quantiles[key][str(m)] is None:
            quantiles[key][str(m)] = allq

# --- 5. isotonic calibration score -> P(flight) ---
from sklearn.isotonic import IsotonicRegression
from sklearn.model_selection import KFold
iso = IsotonicRegression(y_min=0.0, y_max=1.0, out_of_bounds='clip')
iso.fit(df['score'], df['target'])
grid = np.round(np.arange(0.01, 0.9901, 0.01), 2)
probs = iso.predict(grid)
# enforce monotone non-decreasing and round
probs = np.maximum.accumulate(probs)
cal = {'scores': [float(s) for s in grid], 'probs': [round(float(p), 5) for p in probs]}

# quick quality report: cross-validated Brier vs raw
from sklearn.metrics import brier_score_loss
kf = KFold(5, shuffle=True, random_state=42)
briers = []
s = df['score'].to_numpy(); y = df['target'].to_numpy()
for tr, te in kf.split(s):
    m2 = IsotonicRegression(y_min=0, y_max=1, out_of_bounds='clip').fit(s[tr], y[tr])
    briers.append(brier_score_loss(y[te], m2.predict(s[te])))
print('cv brier (calibrated):', round(float(np.mean(briers)), 5),
      '| raw-score brier:', round(float(brier_score_loss(y, s)), 5), flush=True)

# --- 6. context for band design ---
overall = df['score']
for pct in [50, 70, 85, 90, 95, 97, 99]:
    v = float(np.quantile(overall, pct / 100))
    print(f'p{pct}: score={v:.3f} calibratedP={float(iso.predict([v])[0]):.4f}')
print('old thresholds: score .50 -> percentile',
      round(float((overall < 0.50).mean()) * 100, 1),
      ', score .60 -> percentile', round(float((overall < 0.60).mean()) * 100, 1))

# --- 7. HOURLY block (bead nf-k0o) -----------------------------------------
# bandFor() is applied to hourly scores too, but until now flight_stats.json
# carried only the DAILY calibration and quantiles - so an hourly score was
# banded against daily-fitted thresholds, which do not describe the same
# distribution. Fit the hourly equivalents from the same snapshot.
#
# Feature order must match nuptialHourlyPercentageModel exactly: HOURLY_BASE
# with UTC `hour` replaced by cyclical solar_sin/solar_cos, then the 7 shared
# lead-up features (22 total).
HOURLY_SHIPPED = ([f for f in tle.HOURLY_BASE if f != 'hour']
                  + ['solar_sin', 'solar_cos'])

dh = df.dropna(subset=['temp', 'h_windSpeed', 'h_humid', 'h_press',
                       'h_dewPoint', 'hour']).copy()
print(f'hourly rows: {len(dh)} ({dh["target"].mean()*100:.2f}% positive)',
      flush=True)

Xh = dh[HOURLY_SHIPPED + tle.LEADUP_FEATS].astype(float).to_numpy()
hourly_model = json.load(open(f"{REPO}/assets/hour_model.json"))
print('scoring hourly...', flush=True)
raw_h = score_all(Xh, hourly_model)
# Same runtime cutoffs and clamp as nuptialHourlyPercentageModel, but on the
# HOURLY temp/wind/gust rather than the daily ones.
h_temp = dh['temp'].to_numpy(float)
h_wind = dh['h_windSpeed'].to_numpy(float)
h_gust = pd.to_numeric(dh['h_windGust'], errors='coerce').fillna(
    dh['h_windSpeed']).to_numpy(float)
score_h = np.clip(raw_h, 0.01, 0.99)
score_h = np.where((h_temp < 5) | (h_wind > 15) | (h_gust > 20), 0.01, score_h)
dh['score'] = score_h
print('hourly scored. mean', round(float(score_h.mean()), 4), flush=True)

h_hemi = dh['hemisphere'].to_numpy(float)
hourly_quantiles = {'n': {}, 's': {}}
for h, key in [(1.0, 'n'), (0.0, 's')]:
    for m in range(1, 13):
        sel = dh[(h_hemi == h) & (dh['month'] == m)]['score']
        hourly_quantiles[key][str(m)] = (
            [round(float(v), 4) for v in np.quantile(sel, qs)]
            if len(sel) >= 200 else None)
    allq = [round(float(v), 4) for v in np.quantile(dh[h_hemi == h]['score'], qs)]
    hourly_quantiles[key]['all'] = allq
    for m in range(1, 13):
        if hourly_quantiles[key][str(m)] is None:
            hourly_quantiles[key][str(m)] = allq

iso_h = IsotonicRegression(y_min=0.0, y_max=1.0, out_of_bounds='clip')
iso_h.fit(dh['score'], dh['target'])
probs_h = np.maximum.accumulate(iso_h.predict(grid))
cal_h = {'scores': [float(x) for x in grid],
         'probs': [round(float(p), 5) for p in probs_h]}

briers_h = []
sh = dh['score'].to_numpy(); yh = dh['target'].to_numpy()
for tr, te in KFold(5, shuffle=True, random_state=42).split(sh):
    m2 = IsotonicRegression(y_min=0, y_max=1, out_of_bounds='clip').fit(sh[tr], yh[tr])
    briers_h.append(brier_score_loss(yh[te], m2.predict(sh[te])))
h_base = float(dh['target'].mean())
print('hourly cv brier (calibrated):', round(float(np.mean(briers_h)), 5),
      '| raw-score brier:', round(float(brier_score_loss(yh, sh)), 5), flush=True)
print('hourly base_rate:', round(h_base, 5), flush=True)
for mult in (1, 2, 4):
    tgt = mult * h_base
    hit = next((float(x) for x, p in zip(grid, probs_h) if p >= tgt), None)
    print(f'  hourly {mult}x base ({tgt:.5f}) reached at score {hit}')

out = {
    'generated': datetime.now(timezone.utc).strftime('%Y-%m-%d'),
    'rows': int(len(df)),
    'base_rate': round(float(df['target'].mean()), 5),
    'quantile_steps': [round(float(q), 2) for q in qs],
    'quantiles': quantiles,
    'calibration': cal,
    # Sibling block for the hourly model. The app falls back to the daily
    # tables when this key is absent, so an older asset still works.
    'hourly': {
        'rows': int(len(dh)),
        'base_rate': round(h_base, 5),
        'quantiles': hourly_quantiles,
        'calibration': cal_h,
    },
}
with open(f"{REPO}/assets/flight_stats.json", 'w') as f:
    json.dump(out, f, separators=(',', ':'))
print('wrote assets/flight_stats.json', flush=True)
