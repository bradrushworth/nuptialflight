// The OpenWeatherMap key is a live billable credential and the app logs with
// bare `print`, which survives release builds. AGENTS.md forbids logging any
// URL containing `appid=`; these tests pin the redaction that enforces it.
import 'package:flutter_test/flutter_test.dart';
import 'package:nuptialflight/utils.dart';

void main() {
  group('redactUrl', () {
    const String key = 'deadbeefdeadbeefdeadbeefdeadbeef';

    test('strips appid from a One Call timeline URL', () {
      final String url =
          'https://api.openweathermap.org/data/4.0/onecall/timeline/1h'
          '?lat=-35.28&lon=149.13&appid=$key&units=metric&cnt=48';
      final String out = redactUrl(url);
      expect(out, isNot(contains(key)));
      expect(out, contains('appid=REDACTED'));
      // Everything useful for debugging survives.
      expect(out, contains('lat=-35.28'));
      expect(out, contains('lon=149.13'));
      expect(out, contains('cnt=48'));
      expect(out, startsWith('https://api.openweathermap.org/'));
    });

    test('strips appid from the geocoding and 2.5 weather URLs', () {
      for (final String url in <String>[
        'https://api.openweathermap.org/geo/1.0/reverse?lat=1.0&lon=2.0&appid=$key&limit=1',
        'https://api.openweathermap.org/data/2.5/weather?lat=1.0&lon=2.0&appid=$key&units=metric&mode=json',
      ]) {
        expect(redactUrl(url), isNot(contains(key)));
        expect(redactUrl(url), contains('appid=REDACTED'));
      }
    });

    test('redacts other secret parameter names, case-insensitively', () {
      expect(redactUrl('https://x.test/a?APPID=$key'), contains('APPID=REDACTED'));
      expect(redactUrl('https://x.test/a?api_key=$key'), isNot(contains(key)));
      expect(redactUrl('https://x.test/a?token=$key'), isNot(contains(key)));
      expect(redactUrl('https://x.test/a?password=$key'), isNot(contains(key)));
    });

    test('leaves non-secret URLs untouched', () {
      const String plain = 'https://nuptialflight.app/';
      expect(redactUrl(plain), plain);
      const String q = 'https://x.test/a?lat=1.0&lon=2.0';
      expect(redactUrl(q), contains('lat=1.0'));
      expect(redactUrl(q), contains('lon=2.0'));
    });

    test('never echoes input it cannot parse', () {
      expect(redactUrl('::: not a url ::: appid=$key'), '<unparseable url>');
    });
  });
}
