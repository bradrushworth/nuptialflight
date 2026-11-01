# scripts/ — offline pipelines (Python)

Nothing here ships in the app. These regenerate the assets the app *does*
ship, and they talk to the live database and paid APIs. Read before running.

| Script | Does | Cost / risk |
|---|---|---|
| `train_leadup_experiment.py` | Retrain experiments under the honest protocol | DB read, slow |
| `export_leadup_models.py` | Train + export the shipped forests + parity fixtures | DB read |
| `flight_stats_pipeline.py` | Rebuild `assets/flight_stats.json` | DB read |
| `backfill_leadup.py` | Backfill the `leadup` collection | **Paid OWM calls** |
| `test_backfill_leadup.py` | Unit tests for the backfill | free |
| `store/` | Store listing text + screenshots — see `store/AGENTS.md` | free |
| `icon/` | App icon generation | free |

## Credentials

Environment only — never inline, never committed:

Training and stats read as `notebook`, a read-only user (grant `ro` on
`nuptialFlight`; password reset 2026-11-01). Its password lives in
`/root/nuptialflight-notebook-arango-password.txt` on the host and in the
owner's `~/.nuptialflight/training.env`, which also holds the tunnel command.
Reach ArangoDB through an SSH tunnel to the container's internal 8529; the
public 8530 listener is being retired with the legacy users:

```bash
IP=$(ssh ubuntu@host.bitbot.net.au "docker inspect arangodb --format '{{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}'" | awk '{print $1}')
ssh -N -o IdentitiesOnly=yes -i ~/.ssh/id_rsa_aussidex -L 18529:$IP:8529 ubuntu@host.bitbot.net.au &
set -a; . ~/.nuptialflight/training.env; set +a   # ARANGO_URL=http://localhost:18529, ARANGO_USER=notebook
```

`train_leadup_experiment.py`, `export_leadup_models.py` and
`flight_stats_pipeline.py` default to `notebook`. `backfill_leadup.py` has no
default user, because it writes to `leadup`; set `ARANGO_USER` to a user with
rw there. Every password previously committed to this repo must be treated
as **rotated**.

## The evaluation protocol is the point

`train_leadup_experiment.py` exists because the earlier numbers were wrong.
Random `train_test_split` inflated every metric: one user reporting one
flight produces many near-duplicate rows, which straddle a random split and
leak. The honest protocol is:

- **GroupKFold(5) by install**, plus
- per-`(install, location, day)` **dedup** (222,757 → 139,193 rows; positive
  rate 4.8% → 6.9%), plus
- a **temporal holdout** (≥ 2025-09).

Under it, the part-4 models re-baselined from a claimed 0.654/0.670 AUC down
to 0.627/0.640. **Any new accuracy claim must use this protocol**, or it is
not comparable to anything in `docs/model_training_findings.md`.

Current shipped numbers (grouped CV, holdout in parentheses):

| Model | AUC | AP |
|---|---|---|
| daily 28f | 0.660 ±0.015 (0.639) | 0.147 (0.097) |
| hourly 22f | 0.671 ±0.012 (0.666) | 0.149 (0.102) |

The **hourly model is the stronger of the two** — do not assume otherwise
when reasoning about the UI's `minBand` cap (see
[docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md) §4).

## Label leakage — the trap in this dataset

Lead-up features are derived **uniformly for positives and negatives** via a
flights self-join. The backfilled `leadup` collection is positives-only and
is used **only to validate** the derivation (993 overlaps: pressure MAE
1.17 hPa, rain MAE 2.44 mm). Training on it directly would teach the model
"has a lead-up record ⇒ flight". Keep that separation.

## `flight_stats_pipeline.py` must mirror the app exactly

It scores the live DB with the **shipped** daily model and replicates
`nuptialDailyPercentageModel` including hard cutoffs and clamping, so the
quantiles match the distribution users actually see. If you change scoring in
Dart, change it here in the same commit or the bands drift out of alignment
with reality.

It emits **both** blocks: the daily quantiles/calibration at the top level
and a sibling `hourly` block fitted the same way on hourly-scored rows (the
22-feature order, hourly cutoffs on `temp`/`h_windSpeed`/`h_windGust`). The
app reads them via `bandFor()` and `bandForHourly()` respectively.

## After a retrain

1. `export_leadup_models.py` → forests + parity fixtures
2. copy the forests into `assets/`
3. `flight_stats_pipeline.py` → `assets/flight_stats.json`
4. re-pin band anchors in `test/flight_index_test.dart`
5. restore `%TEMP%/ship_expected.json` + `ship_hour_expected.json` and run
   the parity tests — **they self-skip if the fixtures are missing**, so a
   green run without them proves nothing
6. recalibrate gauge/day-quality fixtures in `nuptials_test.dart`

## `backfill_leadup.py` spends money

Paid OWM calls, one per row, operator-run. Idempotent, throttled to 1 rps by
default, supports `--dry-run`. It pauses at the daily call cap; rerunning
resumes free. Don't call it from anything automated.
