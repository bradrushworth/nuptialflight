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

class DecisionTree {
  final List<int> childrenLeft;
  final List<int> childrenRight;
  final List<double> threshold;
  final List<int> feature;
  final List<List<double>> value;

  DecisionTree.fromMap(Map<String, dynamic> m)
      : childrenLeft = List<int>.from(m['children_left']),
        childrenRight = List<int>.from(m['children_right']),
        threshold =
            (m['threshold'] as List).map((e) => (e as num).toDouble()).toList(),
        feature = List<int>.from(m['feature']),
        value = (m['value'] as List)
            .map((row) =>
                (row as List).map((e) => (e as num).toDouble()).toList())
            .toList();

  /// Per-tree class probabilities (normalised leaf value), matching
  /// sklearn's DecisionTreeClassifier.predict_proba.
  List<double> predictProba(List<double> x) {
    int node = 0;
    while (feature[node] != -2) {
      node = x[feature[node]] <= threshold[node]
          ? childrenLeft[node]
          : childrenRight[node];
    }
    final v = value[node];
    double s = 0;
    for (final e in v) {
      s += e;
    }
    return [for (final e in v) e / s];
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