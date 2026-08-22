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
client = ArangoClient(hosts='https://api.bitbot.com.au:8530')
db = client.db('nuptialFlight', username='notebook', password='g54g54gwggsvd')
query = ("FOR f IN flights "
    "RETURN {tgt: f.flight=='yes', lat: f.weather.lat, lon: f.weather.lon, "
    "dt: f.weather.daily[0].dt, day: f.weather.daily[0].temp.day, "
    "windSpeed: f.weather.daily[0].wind_speed, windGust: f.weather.daily[0].wind_gust, "
    "rain0: f.weather.daily[0].pop, rainmm: f.weather.daily[0].rain, "
    "humid: f.weather.daily[0].humidity, cloud: f.weather.daily[0].clouds, "
    "press: f.weather.daily[0].pressure, dewPoint: f.weather.daily[0].dew_point, "
    "uvi: f.weather.daily[0].uvi, moon: f.weather.daily[0].moon_phase, "
    "sunrise: f.weather.daily[0].sunrise, sunset: f.weather.daily[0].sunset, "
    "popNext1: f.weather.daily[1].pop, popNext2: f.weather.daily[2].pop}")
print('fetching...', flush=True)
rows = list(db.aql.execute(query, batch_size=10000))
df = pd.DataFrame(rows)
print(len(df), 'rows fetched', flush=True)

# --- 2. features exactly as nuptials.dart ---
df = df.dropna(subset=['lat', 'lon', 'dt', 'day', 'windSpeed', 'rain0', 'humid',
                       'cloud', 'press', 'dewPoint']).copy()
df['target'] = df.pop('tgt').astype(int)
dts = pd.to_datetime(df['dt'], unit='s', utc=True)
df['month'] = dts.dt.month
doy = dts.dt.dayofyear.to_numpy()

lat = df['lat'].to_numpy(float); lon = df['lon'].to_numpy(float)
temp = df['day'].to_numpy(float)
wind = df['windSpeed'].to_numpy(float)
gust = df['windGust'].fillna(df['windSpeed']).to_numpy(float)
rain0 = df['rain0'].to_numpy(float)
humid = df['humid'].to_numpy(float)
cloud = df['cloud'].to_numpy(float)
press = df['press'].to_numpy(float)
dew = df['dewPoint'].to_numpy(float)
uvi = df['uvi'].fillna(0.0).to_numpy(float)
rainmm = df['rainmm'].fillna(0.0).to_numpy(float)
pop1 = df['popNext1'].fillna(0.0).to_numpy(float)
pop2 = df['popNext2'].fillna(0.0).to_numpy(float)
moon = df['moon'].fillna(0.5).to_numpy(float)
sunrise = df['sunrise'].to_numpy(); sunset = df['sunset'].to_numpy()
daylength = np.where(pd.notna(df['sunrise']) & pd.notna(df['sunset']),
                     np.clip((sunset - sunrise) / 3600.0, 0.0, 24.0), 12.0)
hemi = (lat > 0).astype(float)
sin_doy = np.sin(2 * np.pi * doy / 365.25); cos_doy = np.cos(2 * np.pi * doy / 365.25)
dew_dep = temp - dew
moon_sin = np.sin(2 * np.pi * moon); moon_cos = np.cos(2 * np.pi * moon)

X = np.column_stack([lat, lon, hemi, sin_doy, cos_doy, temp, wind, rain0, humid,
                     cloud, press, dew, dew_dep, pop1, pop2, uvi, gust, rainmm,
                     daylength, moon_sin, moon_cos])

# --- 3. score with the shipped forest (vectorised tree walk) ---
model = json.load(open(f"{REPO}/assets/final_model.json"))
def score_all(X):
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

print('scoring...', flush=True)
raw = score_all(X)
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

out = {
    'generated': '2026-08-22',
    'rows': int(len(df)),
    'base_rate': round(float(df['target'].mean()), 5),
    'quantile_steps': [round(float(q), 2) for q in qs],
    'quantiles': quantiles,
    'calibration': cal,
}
with open(f"{REPO}/assets/flight_stats.json", 'w') as f:
    json.dump(out, f, separators=(',', ':'))
print('wrote assets/flight_stats.json', flush=True)
