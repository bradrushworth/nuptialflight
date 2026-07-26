// Parity tests for the SHIPPED models (assets/final_model.json and
// assets/hour_model.json; retrained 2026-07-26: RF 24 trees,
// max_leaf_nodes=128, min_samples_leaf=5, class_weight='balanced_subsample').
//
// Compares the Dart ForestModel tree-walker against probabilities from the
// Python models (%TEMP%/ship_expected.json, %TEMP%/ship_hour_expected.json;
// 200 held-out rows each, inputs cast to float32 as sklearn does
// internally). Self-skips when the TEMP artifacts are absent (e.g. CI).
import 'dart:convert';
import 'dart:io';

import 'package:nuptialflight/models/forest_model.dart';
import 'package:test/test.dart';

void _checkParity(String assetPath, String expectedPath) {
  final model =
      ForestModel.fromJsonString(File(assetPath).readAsStringSync());
  final expected =
      json.decode(File(expectedPath).readAsStringSync()) as List;
  expect(expected.length, greaterThanOrEqualTo(100));
  double maxErr = 0.0;
  for (final row in expected) {
    final x = (row['x'] as List)
        .map((e) => (e as num).toDouble())
        .toList(growable: false);
    final pPython = (row['p'] as num).toDouble();
    final pDart = model.scorePositive(x);
    final err = (pDart - pPython).abs();
    if (err > maxErr) maxErr = err;
    expect(pDart, closeTo(pPython, 1e-6),
        reason: 'mismatch for x=$x (dart=$pDart python=$pPython)');
  }
  // ignore: avoid_print
  print('$assetPath: parity OK on ${expected.length} rows; max |err| = $maxErr');
}

void main() {
  final temp = Platform.environment['TEMP'] ?? Platform.environment['TMP'];
  final daily = File('$temp/ship_expected.json');
  final hourly = File('$temp/ship_hour_expected.json');

  group('Production model parity', () {
    test('Daily ForestModel matches Python predict_proba', () {
      _checkParity('assets/final_model.json', daily.path);
    }, skip: temp != null && daily.existsSync() ? false : 'TEMP artifacts not present');

    test('Hourly ForestModel matches Python predict_proba', () {
      _checkParity('assets/hour_model.json', hourly.path);
    }, skip: temp != null && hourly.existsSync() ? false : 'TEMP artifacts not present');
  });
}