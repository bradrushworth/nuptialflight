import 'package:nuptialflight/controller/leadup_features.dart';
import 'package:nuptialflight/responses/onecall_response.dart';
import 'package:test/test.dart';

Daily day({double? rain, int? press, double? temp}) => Daily.fromJson({
      'dt': 1700000000,
      if (rain != null) 'rain': rain,
      if (press != null) 'pressure': press,
      if (temp != null) 'temp': {'day': temp},
    });

void main() {
  test('no prev day -> the trained no-coverage row', () {
    final f = leadUpFeaturesAt([day(temp: 25)], 0);
    expect(f.hasPrev1, 0);
    expect(f.daysSinceRain, 2);
    expect(f.vector, LeadUpFeatures.none.vector);
    expect(f.vector.length, 7);
  });

  test('wet yesterday -> days_since_rain 0, deltas computed', () {
    final t = [
      day(rain: 0.0, press: 1010, temp: 18), // prev2 (dry)
      day(rain: 5.0, press: 1008, temp: 19), // prev1 (wet)
      day(rain: 0.0, press: 1014, temp: 24), // today
    ];
    final f = leadUpFeaturesAt(t, 2);
    expect(f.hasPrev1, 1);
    expect(f.prev1Rain, 5.0);
    expect(f.prev2Rain, 0.0);
    expect(f.daysSinceRain, 0);
    expect(f.dPress1, closeTo(6.0, 1e-9)); // 1014 - 1008
    expect(f.dTemp1, closeTo(5.0, 1e-9)); // 24 - 19
    expect(f.warmDryAfterRain, 1); // 5mm in window, dry warm today
  });

  test('wet two days ago only -> days_since_rain 1', () {
    final t = [day(rain: 3.0), day(rain: 0.0), day(rain: 0.0, temp: 15)];
    final f = leadUpFeaturesAt(t, 2);
    expect(f.daysSinceRain, 1);
    expect(f.warmDryAfterRain, 0); // today too cold (<20C)
  });

  test('dry window -> censored at 2; wet today blocks warm_dry', () {
    final dryF = leadUpFeaturesAt([day(rain: 0.1), day(rain: 0.05), day()], 2);
    expect(dryF.daysSinceRain, 2); // both below the 0.2mm wet threshold
    final wetToday =
        leadUpFeaturesAt([day(rain: 2.0), day(rain: 2.0), day(rain: 3.0, temp: 25)], 2);
    expect(wetToday.warmDryAfterRain, 0); // raining today
  });

  test('prev1 exists but prev2 missing (day index 1 of a 2-day lead-up)', () {
    final f = leadUpFeaturesAt([day(rain: 1.0, press: 1000), day(press: 998)], 1);
    expect(f.hasPrev1, 1);
    expect(f.prev2Rain, 0.0);
    expect(f.daysSinceRain, 0); // prev1 wet
    expect(f.dPress1, closeTo(-2.0, 1e-9));
  });

  test('missing pressure/temp on either side -> zero deltas', () {
    final f = leadUpFeaturesAt([day(rain: 0.0), day(press: 1010, temp: 22)], 1);
    expect(f.dPress1, 0.0);
    expect(f.dTemp1, 0.0);
  });
}
