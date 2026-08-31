import 'dart:io';
import 'package:nuptialflight/controller/nuptials.dart';
import 'package:nuptialflight/controller/scoring.dart';
import 'package:nuptialflight/responses/onecall_response.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() {
    Nuptials.loadFromStrings(
      File('assets/final_model.json').readAsStringSync(),
      File('assets/hour_model.json').readAsStringSync(),
    );
  });

  Hourly h() => Hourly.fromJson({
    'dt': 1700000000, 'temp': 22.0, 'wind_speed': 3.0, 'humidity': 60,
    'pressure': 1015, 'dew_point': 12.0, 'uvi': 5.0,
  });
  Daily d() => Daily.fromJson({
    'dt': 1700000000, 'temp': {'day': 25.0}, 'wind_speed': 3.0, 'pop': 0.1,
    'humidity': 60, 'clouds': 30, 'pressure': 1015, 'dew_point': 12.0, 'uvi': 5.0,
  });

  test('hourly: 10 records into 48 slots -> zero-filled tail, no throw', () {
    final out = computeHourlyPercentages(-35.0, 149.0, List.generate(10, (_) => h()), 48);
    expect(out.length, 48);
    expect(out[9], greaterThan(0));
    expect(out.sublist(10), everyElement(0));
  });

  test('daily: 7 records into 8 slots -> zero-filled tail, no throw', () {
    final out = computeDailyPercentages(-35.0, 149.0, List.generate(7, (_) => d()), 8);
    expect(out.length, 8);
    expect(out[6], greaterThan(0));
    expect(out[7], 0);
  });

  test('empty lists are safe', () {
    expect(computeHourlyPercentages(0, 0, [], 48), everyElement(0));
    expect(computeDailyPercentages(0, 0, [], 8), everyElement(0));
  });

  test('hourly scores: 10 records into 48 slots -> zero-filled tail, no throw', () {
    final out = computeHourlyScores(-35.0, 149.0, List.generate(10, (_) => h()), 48);
    expect(out.length, 48);
    expect(out[9], greaterThan(0));
    expect(out.sublist(10), everyElement(0));
  });

  test('percentage wrapper equals (score*100).toInt() slotwise', () {
    final hourlyList = List.generate(10, (_) => h());
    final scores = computeHourlyScores(-35.0, 149.0, hourlyList, 48);
    final percentages = computeHourlyPercentages(-35.0, 149.0, hourlyList, 48);
    for (var i = 0; i < 48; i++) {
      expect(percentages[i], (scores[i] * 100.0).toInt());
    }

    final dailyList = List.generate(7, (_) => d());
    final dailyScores = computeDailyScores(-35.0, 149.0, dailyList, 8);
    final dailyPercentages = computeDailyPercentages(-35.0, 149.0, dailyList, 8);
    for (var i = 0; i < 8; i++) {
      expect(dailyPercentages[i], (dailyScores[i] * 100.0).toInt());
    }
  });
}
