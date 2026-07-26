// Parity test for the RETRAINED (improved) daily model candidate.
//
// The improved RandomForest (150 trees) is too large to export via m2cgen to
// a compilable Dart score() (~82 MB), so this test validates the sklite JSON
// export instead: it loads %TEMP%/final_model_improved.json, computes
// sklearn-style predict_proba (mean of per-tree normalised leaf values) with
// a small tree-walker, and compares against probabilities produced by the
// Python model (%TEMP%/expected.json, written by the training pipeline).
//
// The test SKIPS itself when the TEMP artifacts are absent (e.g. on CI),
// so it only runs on the machine where the retraining pipeline was executed.
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:test/test.dart';

class _Tree {
  final List<int> childrenLeft;
  final List<int> childrenRight;
  final List<double> threshold;
  final List<int> feature;
  final List<List<double>> value;

  _Tree(Map<String, dynamic> m)
      : childrenLeft = List<int>.from(m['children_left']),
        childrenRight = List<int>.from(m['children_right']),
        threshold =
            (m['threshold'] as List).map((e) => (e as num).toDouble()).toList(),
        feature = List<int>.from(m['feature']),
        value = (m['value'] as List)
            .map((row) =>
                (row as List).map((e) => (e as num).toDouble()).toList())
            .toList();

  /// Per-tree class probabilities (normalised leaf value), like
  /// sklearn DecisionTreeClassifier.predict_proba.
  List<double> predictProba(Float32List x) {
    int node = 0;
    while (feature[node] != -2) {
      node = x[feature[node]] <= threshold[node]
          ? childrenLeft[node]
          : childrenRight[node];
    }
    final v = value[node];
    final s = v[0] + v[1];
    return [v[0] / s, v[1] / s];
  }
}

void main() {
  final temp = Platform.environment['TEMP'] ?? Platform.environment['TMP'];
  final modelFile = File('$temp/final_model_improved.json');
  final expectedFile = File('$temp/expected.json');
  final available =
      temp != null && modelFile.existsSync() && expectedFile.existsSync();

  group('Improved Daily Model (retrain candidate)', () {
    test('Dart sklite-JSON predict_proba matches Python predict_proba', () {
      final model =
          json.decode(modelFile.readAsStringSync()) as Map<String, dynamic>;
      final trees = (model['dtrees'] as List)
          .map((t) => _Tree(t as Map<String, dynamic>))
          .toList();
      expect(trees.length, 150);

      final expected = json.decode(expectedFile.readAsStringSync()) as List;
      expect(expected.length, greaterThanOrEqualTo(100));

      double maxErr = 0.0;
      for (final row in expected) {
        // sklearn casts X to float32 before tree traversal; reproduce that.
        final x = Float32List.fromList((row['x'] as List)
            .map((e) => (e as num).toDouble())
            .toList(growable: false));
        final pPython = (row['p'] as num).toDouble();
        double p1 = 0.0;
        for (final t in trees) {
          p1 += t.predictProba(x)[1];
        }
        p1 /= trees.length;
        final err = (p1 - pPython).abs();
        if (err > maxErr) maxErr = err;
        expect(p1, closeTo(pPython, 1e-6),
            reason: 'mismatch for x=$x (dart=$p1 python=$pPython)');
      }
      // ignore: avoid_print
      print(
          'Parity OK on ${expected.length} holdout rows; max |err| = $maxErr');
    }, skip: available ? false : 'TEMP model artifacts not present');
  });
}