// Hand-written RandomForest scorer over the sklite-exported JSON assets
// (assets/final_model.json, assets/hour_model.json).
//
// Replaces the previous m2cgen-generated Dart score() trees (~700 KB each)
// with the same math driven from the bundled JSON: sklearn-style
// predict_proba = mean over trees of the normalised leaf class counts.
// Parity with Python predict_proba is verified to ~1e-14 by
// test/production_model_parity_test.dart and test/hourly_test.dart.
//
// This file is pure Dart (no Flutter imports) so plain `package:test` tests
// can use it by reading the JSON straight from the file system.
import 'dart:convert';
import 'dart:typed_data';

class DecisionTree {
  // Typed arrays, not List<int>/List<double>: a growable list holds one boxed
  // object per number, so the two forests kept that many small objects alive
  // for the whole session and every full garbage collection had to walk them.
  // The UI isolate shares Android's main thread, and those collections showed
  // up in Play vitals as ANRs. A typed array is a single object.
  final Int32List childrenLeft;
  final Int32List childrenRight;
  final Float64List threshold;
  final Int32List feature;

  /// Leaf class counts, row-major: node i's counts are
  /// `value[i * classCount]` up to `value[(i + 1) * classCount - 1]`.
  final Float64List value;
  final int classCount;

  DecisionTree._(this.childrenLeft, this.childrenRight, this.threshold,
      this.feature, this.value, this.classCount);

  factory DecisionTree.fromMap(Map<String, dynamic> m) {
    final rows = m['value'] as List;
    final classCount = rows.isEmpty ? 0 : (rows.first as List).length;
    final value = Float64List(rows.length * classCount);
    for (int i = 0; i < rows.length; i++) {
      final row = rows[i] as List;
      if (row.length != classCount) {
        throw FormatException(
            'Tree value rows differ in length: ${row.length} != $classCount');
      }
      for (int c = 0; c < classCount; c++) {
        value[i * classCount + c] = (row[c] as num).toDouble();
      }
    }
    return DecisionTree._(
      Int32List.fromList(List<int>.from(m['children_left'])),
      Int32List.fromList(List<int>.from(m['children_right'])),
      Float64List.fromList([
        for (final e in m['threshold'] as List) (e as num).toDouble(),
      ]),
      Int32List.fromList(List<int>.from(m['feature'])),
      value,
      classCount,
    );
  }

  /// Per-tree class probabilities (normalised leaf value), matching
  /// sklearn's DecisionTreeClassifier.predict_proba.
  List<double> predictProba(List<double> x) {
    int node = 0;
    while (feature[node] != -2) {
      node = x[feature[node]] <= threshold[node]
          ? childrenLeft[node]
          : childrenRight[node];
    }
    final start = node * classCount;
    double s = 0;
    for (int c = 0; c < classCount; c++) {
      s += value[start + c];
    }
    return [for (int c = 0; c < classCount; c++) value[start + c] / s];
  }
}

/// A RandomForestClassifier reconstructed from a sklite JSON export.
class ForestModel {
  final List<DecisionTree> trees;
  final List<int> classes;

  ForestModel(this.trees, this.classes);

  factory ForestModel.fromJsonString(String jsonString) {
    final map = json.decode(jsonString) as Map<String, dynamic>;
    return ForestModel(
      (map['dtrees'] as List)
          .map((t) => DecisionTree.fromMap(t as Map<String, dynamic>))
          .toList(),
      List<int>.from(map['classes']),
    );
  }

  /// sklearn-style predict_proba: mean of the per-tree probabilities.
  List<double> predictProba(List<double> x) {
    final acc = List<double>.filled(classes.length, 0.0);
    for (final t in trees) {
      final p = t.predictProba(x);
      for (int i = 0; i < acc.length; i++) {
        acc[i] += p[i];
      }
    }
    for (int i = 0; i < acc.length; i++) {
      acc[i] /= trees.length;
    }
    return acc;
  }

  /// Probability of the positive class (a nuptial flight).
  double scorePositive(List<double> x) => predictProba(x)[1];
}