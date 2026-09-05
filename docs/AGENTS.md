# docs/ — reference documentation

Long-form background. The root [AGENTS.md](../AGENTS.md) is the canonical
agent context; these are the deeper dives it points at.

| Doc | Covers | Read it when |
|---|---|---|
| [`ARCHITECTURE.md`](ARCHITECTURE.md) | System shape, the four layers, invariants | Orienting, or changing anything cross-cutting |
| [`model_training_findings.md`](model_training_findings.md) | Every retrain, its metrics, and what shipped | Touching models, features or accuracy claims |
| [`database_schema.md`](database_schema.md) | ArangoDB collections | Touching `arangodb.dart` or training data |
| [`map_shading.md`](map_shading.md) | Map overlay tinting from PD optima | Touching `view/map.dart` |

Per-folder notes live in `AGENTS.md` inside each source folder
(`lib/`, `lib/controller/`, `lib/view/`, `test/`, `scripts/`, …).

## Conventions for this folder

- **`model_training_findings.md` is append-only, in parts.** Each retrain
  adds a `## Part N` section rather than rewriting history. That history is
  the reason the honest-evaluation re-baseline is traceable — do not tidy
  away superseded numbers, mark them superseded.
- **Quote metrics with their protocol.** An AUC without "grouped CV + dedup +
  temporal holdout" is not comparable to anything current here. The older
  random-split numbers (0.654/0.670) are inflated and are kept only for
  contrast.
- **Record what did NOT ship, and why.** Several sections document rejected
  candidates (the 150-tree forest at 82 MB of Dart, `CalibratedClassifierCV`,
  visibility as a feature). That is the most reused part of this file.
- Convert relative dates to absolute ones — these documents outlive the
  session that wrote them.
