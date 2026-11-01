import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nuptialflight/controller/nuptials.dart';
import 'package:nuptialflight/models/forest_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ensureLoaded parses both bundled models off the UI isolate', () async {
    await Nuptials.ensureLoaded();
    final daily = ForestModel.fromJsonString(
        File('assets/final_model.json').readAsStringSync());
    final hourly = ForestModel.fromJsonString(
        File('assets/hour_model.json').readAsStringSync());

    expect(Nuptials().daily.trees.length, daily.trees.length);
    expect(Nuptials().hourly.trees.length, hourly.trees.length);
    final x28 = List<double>.generate(28, (i) => i * 0.37 - 3);
    final x22 = List<double>.generate(22, (i) => i * 0.41 - 2);
    expect(Nuptials().daily.scorePositive(x28), daily.scorePositive(x28));
    expect(Nuptials().hourly.scorePositive(x22), hourly.scorePositive(x22));
  });

  test('trees hold their arrays as typed data', () {
    // Play vitals, 2.29.1: ANRs with the main thread inside Dart garbage
    // collection. As growable lists the two forests kept one boxed object
    // per number alive for the whole session; a typed array is one object.
    final tree = ForestModel.fromJsonString(
            File('assets/final_model.json').readAsStringSync())
        .trees
        .first;
    expect(tree.childrenLeft, isA<Int32List>());
    expect(tree.childrenRight, isA<Int32List>());
    expect(tree.feature, isA<Int32List>());
    expect(tree.threshold, isA<Float64List>());
    expect(tree.value, isA<Float64List>());
    expect(tree.value.length, tree.feature.length * tree.classCount);
  });

  test('rejects a tree whose value rows differ in length', () {
    expect(
      () => DecisionTree.fromMap({
        'children_left': [1, -1, -1],
        'children_right': [2, -1, -1],
        'threshold': [0.5, -2.0, -2.0],
        'feature': [0, -2, -2],
        'value': [
          [1.0, 1.0],
          [1.0],
          [0.0, 1.0],
        ],
      }),
      throwsFormatException,
    );
  });
}
