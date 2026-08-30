"""Retrain experiment: lead-up features + honest evaluation (2026-08-30).

Measures, under GROUPED cross-validation (GroupKFold by install) with per
(install, location, day) dedup — the Tier-1 protocol from the accuracy
review — plus a temporal holdout:

  Daily model:   A = current 21-feature production set (honest re-baseline)
                 B = A + 7 derived lead-up features
  Hourly model:  HA = current 14-feature production set (re-baseline)
                 HB = HA with UTC hour replaced by cyclical LOCAL SOLAR hour
                 HC = HB + the lead-up features

Lead-up features are derived UNIFORMLY for positives and negatives by
self-joining flights against itself (same install - else same ~11 km
location cell - on day-1/day-2, whose daily[0] is that day's weather).
The positives-only backfilled `leadup` collection is used for VALIDATION of
the derived values, never as a training feature source (a positives-only
feature would teach "has lead-up => flight").

Credentials come from ARANGO_* env vars (password required). Results are
printed and written to %TEMP%/leadup_experiment_results.json. Nothing is
exported for the app; shipping is a separate, explicit step.

Usage:  python scripts/train_leadup_experiment.py [--quick]
"""
import argparse
import json
import os
import sys
import tempfile
import time

import numpy as np
import pandas as pd
from arango import ArangoClient
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import average_precision_score, roc_auc_score
from sklearn.model_selection import GroupKFold

ONE_DAY = 86400
RAIN_WET_MM = 0.2  # daily rain-amount above this counts as "a wet day"
HOLDOUT_FROM = int(pd.Timestamp('2025-09-01', tz='UTC').timestamp())

RF = dict(n_estimators=48, max_features='sqrt', min_samples_leaf=5,
          max_leaf_nodes=256, class_weight='balanced_subsample',
          random_state=42, n_jobs=-1)

DAILY_BASE = ['lat', 'lon', 'hemisphere', 'sin_doy', 'cos_doy', 'day',
              'windSpeed', 'rain0', 'humid', 'cloud', 'press', 'dewPoint',
              'dew_dep', 'popNext1', 'popNext2', 'uvi', 'windGust', 'rainmm',
              'daylength', 'moon_sin', 'moon_cos']
LEADUP_FEATS = ['prev1_rain', 'prev2_rain', 'dpress1', 'dtemp1',
                'days_since_rain', 'warm_dry_after_rain', 'has_prev1']
HOURLY_BASE = ['lat', 'lon', 'hemisphere', 'sin_doy', 'cos_doy', 'hour',
               'temp', 'h_windSpeed', 'h_humid', 'h_press', 'h_dewPoint',
               'h_dew_dep', 'h_uvi', 'h_windGust']


def connect():
    url = os.environ.get('ARANGO_URL', 'https://api.bitbot.com.au:8530')
    dbname = os.environ.get('ARANGO_DB_NAME', 'nuptialFlight')
    user = os.environ.get('ARANGO_USER', 'nuptialflight')
    password = os.environ.get('ARANGO_PASSWORD')
    if not password:
        sys.exit('ARANGO_PASSWORD env var is required')
    return ArangoClient(hosts=url).db(dbname, username=user, password=password)


def fetch(db):
    """One projected pass over flights with both daily[0] and hourly[0]."""
    q = ("FOR f IN flights "
         "FILTER f.weather.daily != null AND LENGTH(f.weather.daily) > 0 "
         "RETURN {key: f._key, tgt: f.flight=='yes', inst: f.install_id, "
         "dev: f.device_id, lat: f.weather.lat, lon: f.weather.lon, "
         "dt: f.weather.daily[0].dt, day: f.weather.daily[0].temp.day, "
         "windSpeed: f.weather.daily[0].wind_speed, windGust: f.weather.daily[0].wind_gust, "
         "rain0: f.weather.daily[0].pop, rainmm: f.weather.daily[0].rain, "
         "humid: f.weather.daily[0].humidity, cloud: f.weather.daily[0].clouds, "
         "press: f.weather.daily[0].pressure, dewPoint: f.weather.daily[0].dew_point, "
         "uvi: f.weather.daily[0].uvi, moon: f.weather.daily[0].moon_phase, "
         "sunrise: f.weather.daily[0].sunrise, sunset: f.weather.daily[0].sunset, "
         "popNext1: f.weather.daily[1].pop, popNext2: f.weather.daily[2].pop, "
         "h_dt: f.weather.hourly[0].dt, h_temp: f.weather.hourly[0].temp, "
         "h_windSpeed: f.weather.hourly[0].wind_speed, h_windGust: f.weather.hourly[0].wind_gust, "
         "h_humid: f.weather.hourly[0].humidity, h_press: f.weather.hourly[0].pressure, "
         "h_dewPoint: f.weather.hourly[0].dew_point, h_uvi: f.weather.hourly[0].uvi}")
    t0 = time.time()
    rows = list(db.aql.execute(q, batch_size=10000, ttl=3600))
    print(f'fetched {len(rows)} flights rows in {time.time()-t0:.0f}s', flush=True)
    return pd.DataFrame(rows)


def fetch_backfill_sample(db, limit=3000):
    q = ("FOR d IN leadup FILTER d.source == 'backfill' LIMIT @lim "
         "RETURN {key: d._key, daily: d.weather.leadup.daily}")
    try:
        return list(db.aql.execute(q, bind_vars={'lim': limit}))
    except Exception as e:  # collection may be mid-backfill; validation is optional
        print('leadup validation fetch failed (non-fatal):', e, flush=True)
        return []


def engineer(df):
    df = df.copy()
    df['target'] = df.pop('tgt').astype(int)
    for c in ['rainmm', 'popNext1', 'popNext2']:
        df[c] = pd.to_numeric(df[c], errors='coerce').fillna(0)
    df['windGust'] = pd.to_numeric(df['windGust'], errors='coerce').fillna(df['windSpeed'])
    df['uvi'] = pd.to_numeric(df['uvi'], errors='coerce')
    df['uvi'] = df['uvi'].fillna(df['uvi'].median())
    df['moon'] = pd.to_numeric(df['moon'], errors='coerce').fillna(0.5)
    df = df.dropna(subset=['lat', 'lon', 'dt', 'day', 'windSpeed', 'rain0',
                           'humid', 'cloud', 'press', 'dewPoint'])
    dts = pd.to_datetime(df['dt'], unit='s', utc=True)
    doy = dts.dt.dayofyear.to_numpy()
    df['hemisphere'] = (df['lat'] > 0).astype(int)
    df['sin_doy'] = np.sin(2 * np.pi * doy / 365.25)
    df['cos_doy'] = np.cos(2 * np.pi * doy / 365.25)
    df['dew_dep'] = df['day'] - df['dewPoint']
    dl = (df['sunset'] - df['sunrise']) / 3600.0
    dl = dl.where((dl > 0) & (dl < 24))
    df['daylength'] = dl.fillna(dl.median())
    df['moon_sin'] = np.sin(2 * np.pi * df['moon'])
    df['moon_cos'] = np.cos(2 * np.pi * df['moon'])
    # Hourly-side engineering (rows lacking hourly[0] are dropped only for
    # the hourly variants, later).
    df['h_windGust'] = pd.to_numeric(df['h_windGust'], errors='coerce').fillna(df['h_windSpeed'])
    df['h_uvi'] = pd.to_numeric(df['h_uvi'], errors='coerce')
    df['h_uvi'] = df['h_uvi'].fillna(df['h_uvi'].median())
    df.rename(columns={'h_temp': 'temp'}, inplace=True)
    df['h_dew_dep'] = df['temp'] - df['h_dewPoint']
    h_dts = pd.to_datetime(df['h_dt'], unit='s', utc=True, errors='coerce')
    df['hour'] = h_dts.dt.hour  # UTC hour, as in production
    # Cyclical LOCAL SOLAR hour (roadmap lever 06): lon/15 h offset from UTC.
    solar = (df['hour'] + df['lon'] / 15.0) % 24
    df['solar_sin'] = np.sin(2 * np.pi * solar / 24)
    df['solar_cos'] = np.cos(2 * np.pi * solar / 24)
    # Group + join keys.
    df['dayb'] = (df['dt'] // ONE_DAY).astype(int)
    df['loc'] = list(zip(df['lat'].round(1), df['lon'].round(1)))
    df['group'] = df['inst'].fillna(df['dev']).fillna(df['loc'].astype(str))
    return df


def add_leadup(df):
    """Self-join lead-up features, uniform for both classes."""
    # Per (install, day) and per (loc-cell, day) medians of the day's weather.
    # Plain dict lookups: a MultiIndex whose level values are themselves
    # tuples (the loc cell) confuses DataFrame.loc, and dicts are faster for
    # 220k x 2 point lookups anyway. Values: (rainmm, press, temp_day).
    day_w = {k: (v['rainmm'], v['press'], v['day'])
             for k, v in df.groupby(['loc', 'dayb'])[['rainmm', 'press', 'day']]
                          .median().to_dict('index').items()}
    inst_w = {k: (v['rainmm'], v['press'], v['day'])
              for k, v in df.groupby(['group', 'dayb'])[['rainmm', 'press', 'day']]
                           .median().to_dict('index').items()}

    prev1_rain = np.zeros(len(df)); prev2_rain = np.zeros(len(df))
    dpress1 = np.zeros(len(df)); dtemp1 = np.zeros(len(df))
    has1 = np.zeros(len(df)); has2 = np.zeros(len(df))
    groups = df['group'].to_numpy(); locs = df['loc'].to_numpy(object)
    days = df['dayb'].to_numpy(); press = df['press'].to_numpy()
    tday = df['day'].to_numpy()
    for i in range(len(df)):
        for back, rain_arr, has_arr in ((1, prev1_rain, has1), (2, prev2_rain, has2)):
            src = inst_w.get((groups[i], days[i] - back)) \
                or day_w.get((locs[i], days[i] - back))
            if src is None:
                continue
            has_arr[i] = 1
            rain_arr[i] = 0.0 if pd.isna(src[0]) else float(src[0])
            if back == 1:
                if not pd.isna(src[1]):
                    dpress1[i] = press[i] - float(src[1])
                if not pd.isna(src[2]):
                    dtemp1[i] = tday[i] - float(src[2])
    df['prev1_rain'] = prev1_rain
    df['prev2_rain'] = prev2_rain
    df['dpress1'] = dpress1
    df['dtemp1'] = dtemp1
    df['has_prev1'] = has1
    # days_since_rain censored at 2 (the window the app can see at runtime);
    # no-coverage rows sit at the censor value with has_prev1=0 as the flag.
    df['days_since_rain'] = np.where((has1 == 1) & (prev1_rain > RAIN_WET_MM), 0,
                             np.where((has2 == 1) & (prev2_rain > RAIN_WET_MM), 1, 2))
    df['warm_dry_after_rain'] = (((prev1_rain + prev2_rain) > 1.0)
                                 & (df['rainmm'] < RAIN_WET_MM)
                                 & (df['day'] >= 20)).astype(int)
    cov1 = has1.mean(); cov_pos = has1[df['target'] == 1].mean()
    print(f'lead-up coverage: prev1 {cov1:.1%} overall, {cov_pos:.1%} positives', flush=True)
    return df, {'coverage_prev1': cov1, 'coverage_prev1_positives': cov_pos}


def dedup(df):
    before = len(df)
    df = (df.sort_values('target', ascending=False)
            .drop_duplicates(subset=['group', 'loc', 'dayb'], keep='first'))
    print(f'dedup: {before} -> {len(df)} rows '
          f'({df.target.mean():.4f} positive rate)', flush=True)
    return df


def evaluate(df, feats, label, folds):
    d = df.dropna(subset=feats)
    cv = d[d['dt'] < HOLDOUT_FROM]
    ho = d[d['dt'] >= HOLDOUT_FROM]
    X = cv[feats].astype(float).to_numpy()
    y = cv['target'].to_numpy()
    g = cv['group'].to_numpy()
    aucs, aps = [], []
    for tr, te in GroupKFold(n_splits=folds).split(X, y, g):
        if y[te].sum() == 0 or y[tr].sum() == 0:
            continue
        m = RandomForestClassifier(**RF).fit(X[tr], y[tr])
        p = m.predict_proba(X[te])[:, 1]
        aucs.append(roc_auc_score(y[te], p))
        aps.append(average_precision_score(y[te], p))
    res = {'variant': label, 'n_cv': len(cv), 'n_holdout': len(ho),
           'cv_auc': float(np.mean(aucs)), 'cv_auc_std': float(np.std(aucs)),
           'cv_ap': float(np.mean(aps)), 'cv_ap_std': float(np.std(aps))}
    if len(ho) > 200 and ho['target'].sum() >= 20:
        m = RandomForestClassifier(**RF).fit(X, y)
        ph = m.predict_proba(ho[feats].astype(float).to_numpy())[:, 1]
        res['holdout_auc'] = float(roc_auc_score(ho['target'], ph))
        res['holdout_ap'] = float(average_precision_score(ho['target'], ph))
    print(f"{label}: CV AUC {res['cv_auc']:.4f}±{res['cv_auc_std']:.4f} "
          f"AP {res['cv_ap']:.4f}±{res['cv_ap_std']:.4f} "
          f"holdout AUC {res.get('holdout_auc', float('nan')):.4f} "
          f"AP {res.get('holdout_ap', float('nan')):.4f}", flush=True)
    return res


def validate_derived(df, backfill_rows):
    """Compare self-join prev1 values vs the real backfilled lead-up docs."""
    if not backfill_rows:
        return {'validated': 0}
    real = {}
    for r in backfill_rows:
        days = r.get('daily') or []
        if days:
            last = days[-1]  # day-1 record (window is ascending, before report day)
            real[r['key']] = (last.get('rain') or 0.0, last.get('pressure'))
    sub = df[(df['key'].isin(real)) & (df['has_prev1'] == 1)]
    if sub.empty:
        return {'validated': 0}
    rain_err, press_err = [], []
    for _, row in sub.iterrows():
        rr, rp = real[row['key']]
        rain_err.append(abs(row['prev1_rain'] - (rr or 0.0)))
        if rp is not None:
            press_err.append(abs((row['press'] - row['dpress1']) - rp))
    out = {'validated': int(len(sub)),
           'rain_mae_mm': float(np.mean(rain_err)),
           'wet_day_agreement': float(np.mean(
               [(a > RAIN_WET_MM) == ((real[k][0] or 0.0) > RAIN_WET_MM)
                for a, k in zip(sub['prev1_rain'], sub['key'])]))}
    if press_err:
        out['press_mae_hpa'] = float(np.mean(press_err))
    print(f"derived-vs-backfill validation: n={out['validated']} "
          f"rain MAE {out['rain_mae_mm']:.2f}mm "
          f"press MAE {out.get('press_mae_hpa', float('nan')):.2f}hPa", flush=True)
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--quick', action='store_true', help='30k-row, 3-fold smoke run')
    args = ap.parse_args()
    folds = 3 if args.quick else 5

    db = connect()
    df = engineer(fetch(db))
    df, coverage = add_leadup(df)
    backfill = fetch_backfill_sample(db)
    validation = validate_derived(df, backfill)
    df = dedup(df)
    if args.quick and len(df) > 30000:
        df = df.sample(30000, random_state=42)
        print('quick mode: sampled 30000 rows', flush=True)

    results = {'coverage': coverage, 'validation': validation, 'runs': []}
    # Daily model variants.
    results['runs'].append(evaluate(df, DAILY_BASE, 'daily A (21f re-baseline)', folds))
    results['runs'].append(evaluate(df, DAILY_BASE + LEADUP_FEATS, 'daily B (+leadup)', folds))
    # Hourly variants on rows that have hourly[0].
    dh = df.dropna(subset=['temp', 'h_windSpeed', 'h_humid', 'h_press', 'h_dewPoint', 'hour'])
    print(f'hourly rows after dropna: {len(dh)}', flush=True)
    results['runs'].append(evaluate(dh, HOURLY_BASE, 'hourly HA (14f re-baseline)', folds))
    hb = [f for f in HOURLY_BASE if f != 'hour'] + ['solar_sin', 'solar_cos']
    results['runs'].append(evaluate(dh, hb, 'hourly HB (solar hour)', folds))
    results['runs'].append(evaluate(dh, hb + LEADUP_FEATS, 'hourly HC (solar + leadup)', folds))

    out = os.path.join(tempfile.gettempdir(), 'leadup_experiment_results.json')
    with open(out, 'w') as f:
        json.dump(results, f, indent=1)
    print('wrote', out, flush=True)


if __name__ == '__main__':
    main()
