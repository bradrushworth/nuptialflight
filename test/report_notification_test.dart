import 'package:flutter_test/flutter_test.dart';
import 'package:nuptialflight/controller/services.dart';

void main() {
  group('shouldNotifyReports', () {
    test('stays silent on the first pass after install, even with reports', () {
      // A fresh install has no stored check time, so the first pass looks back
      // 30 minutes and can find reports the user has no context for.
      expect(shouldNotifyReports(firstRun: true, numFlights: 3), isFalse);
    });

    test('notifies on later passes when flights were reported', () {
      expect(shouldNotifyReports(firstRun: false, numFlights: 1), isTrue);
    });

    test('stays silent when nothing was reported', () {
      expect(shouldNotifyReports(firstRun: false, numFlights: 0), isFalse);
      expect(shouldNotifyReports(firstRun: true, numFlights: 0), isFalse);
    });
  });

  group('reportWindowMinutes', () {
    final now = DateTime.utc(2026, 8, 25, 12, 0);

    test('uses the default window when nothing has been checked yet', () {
      expect(reportWindowMinutes(now: now, lastCheck: null),
          defaultReportWindowMinutes);
    });

    test('uses the elapsed time between checks in the normal case', () {
      expect(
          reportWindowMinutes(
              now: now, lastCheck: now.subtract(const Duration(minutes: 47))),
          47);
    });

    test('never looks further back than the maximum window', () {
      // The regression: a last_check_date restored by Android Auto Backup can
      // predate the install by days, which produced a 2911-minute lookback and
      // a "current flight" push about sightings two days old.
      expect(
          reportWindowMinutes(
              now: now, lastCheck: now.subtract(const Duration(minutes: 2911))),
          maxReportWindowMinutes);
      expect(
          reportWindowMinutes(
              now: now, lastCheck: now.subtract(const Duration(days: 400))),
          maxReportWindowMinutes);
    });

    test('the maximum window keeps the alert honestly current', () {
      expect(maxReportWindowMinutes, lessThanOrEqualTo(180));
      expect(maxReportWindowMinutes,
          greaterThanOrEqualTo(defaultReportWindowMinutes));
    });

    test('falls back to the default when the stored check is not in the past',
        () {
      // A clock change, or prefs restored from a device in another timezone,
      // can leave a future timestamp: that must not mean a zero or negative
      // window.
      expect(reportWindowMinutes(now: now, lastCheck: now),
          defaultReportWindowMinutes);
      expect(
          reportWindowMinutes(
              now: now, lastCheck: now.add(const Duration(hours: 9))),
          defaultReportWindowMinutes);
    });
  });
}
