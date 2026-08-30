"""Train + export the lead-up retrained models (2026-08-30 experiment winners).

Trains daily variant B (21 production features + 7 lead-up) and hourly
variant HC (solar-hour + lead-up, 22 features) on ALL deduped rows, and
writes to %TEMP% (NOT assets/ — shipping is a separate decision):

  final_model_leadup.json / hour_model_leadup.json   sklite-format forests
      (the exact key set lib/models/forest_model.dart walks)
  ship_leadup_expected.json / ship_hour_leadup_expected.json
      200-row float32 parity fixtures (predict_proba on held-back rows)
  leadup_features_daily.json / leadup_features_hourly.json
      ordered feature-name manifests (the future nuptials.dart contract)

Reuses the experiment module's fetch/engineering so train-time features are
byte-identical to the measured ones. Env: ARANGO_* (password required).
"""
import json
import os
import sys
import tempfile

import numpy as np
from sklearn.ensemble import RandomForestClassifier

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import train_leadup_experiment as tle  # noqa: E402

TMP = tempfile.gettempdir()


def to_sklite(model):
    """Serialize an sklearn RandomForestClassifier into the JSON shape
    lib/models/forest_model.dart walks (same keys as sklite's LazyExport)."""
    dtrees = []
    for est in model.estimators_:
        t = est.tree_
        dtrees.append({
            'children_left': t.children_left.tolist(),
            'children_right': t.children_right.tolist(),
            'threshold': t.threshold.tolist(),
            'feature': t.feature.tolist(),
            'classes': model.classes_.tolist(),
            'value': [row[0].tolist() for row in t.value],
        })
    return {'classes': model.classes_.tolist(), 'dtrees': dtrees}


def train_export(df, feats, model_file, expected_file, manifest_file, label):
    d = df.dropna(subset=feats)
    X = d[feats].astype(float).to_numpy()
    y = d['target'].to_numpy()
    # Hold the last 200 rows out of the fit purely as a parity fixture set
    # (fixture rows must not require the model to have seen them, but a
    # fixture of trained-on rows would also be fine for parity purposes;
    # excluding them costs nothing).
    fit_X, fit_y = X[:-200], y[:-200]
    m = RandomForestClassifier(**tle.RF).fit(fit_X, fit_y)
    blob = to_sklite(m)
    path = os.path.join(TMP, model_file)
    with open(path, 'w') as f:
        json.dump(blob, f)
    size_mb = os.path.getsize(path) / 1e6
    fx = X[-200:].astype(np.float32).astype(float)  # sklearn scores in float32
    pp = m.predict_proba(fx)[:, 1]
    with open(os.path.join(TMP, expected_file), 'w') as f:
        json.dump([{'x': list(map(float, fx[i])), 'p': float(pp[i])}
                   for i in range(len(fx))], f)
    with open(os.path.join(TMP, manifest_file), 'w') as f:
        json.dump({'features': feats}, f, indent=1)
    print(f'{label}: trained on {len(fit_X)} rows, {len(feats)} features, '
          f'{model_file} = {size_mb:.2f} MB', flush=True)


def main():
    db = tle.connect()
    df = tle.engineer(tle.fetch(db))
    df, _ = tle.add_leadup(df)
    df = tle.dedup(df)

    daily_feats = tle.DAILY_BASE + tle.LEADUP_FEATS
    train_export(df, daily_feats, 'final_model_leadup.json',
                 'ship_leadup_expected.json', 'leadup_features_daily.json',
                 'daily B (28f)')

    dh = df.dropna(subset=['temp', 'h_windSpeed', 'h_humid', 'h_press',
                           'h_dewPoint', 'hour'])
    hourly_feats = ([f for f in tle.HOURLY_BASE if f != 'hour']
                    + ['solar_sin', 'solar_cos'] + tle.LEADUP_FEATS)
    train_export(dh, hourly_feats, 'hour_model_leadup.json',
                 'ship_hour_leadup_expected.json', 'leadup_features_hourly.json',
                 'hourly HC (22f)')


if __name__ == '__main__':
    main()
