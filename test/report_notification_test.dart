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
}
