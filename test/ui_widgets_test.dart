// Widget tests for the redesigned home-screen components. Each test pumps at
// a phone-sized viewport so any RenderFlex overflow fails the test.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuptialflight/controller/flight_index.dart';
import 'package:nuptialflight/controller/units.dart';
import 'package:nuptialflight/l10n/app_localizations.dart';
import 'package:nuptialflight/view/hero_card.dart';
import 'package:nuptialflight/view/hourly_chart.dart';
import 'package:nuptialflight/view/report_sheet.dart';
import 'package:nuptialflight/view/verdict.dart';
import 'package:nuptialflight/view/week_list.dart';
import 'package:nuptialflight/view/why_panel.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3D6B4F)),
      useMaterial3: true,
    ),
    home: Scaffold(
      body: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  );
}

void _phoneSized(WidgetTester tester) {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

void main() {
  group('Verdict', () {
    test('thresholds map to the right labels', () {
      expect(verdictFor(60), Verdict.likely);
      expect(verdictFor(59), Verdict.possible);
      expect(verdictFor(50), Verdict.possible);
      expect(verdictFor(49), Verdict.unlikely);
      expect(verdictFor(0), Verdict.unlikely);
      expect(verdictLabel(Verdict.likely), 'Likely');
      expect(verdictLabel(Verdict.possible), 'Possible');
      expect(verdictLabel(Verdict.unlikely), 'Unlikely');
    });
  });

  group('Units', () {
    tearDown(() => Units.imperial.value = false);

    test('metric formatting', () {
      Units.imperial.value = false;
      expect(Units.temp(27.24), '27.2°C');
      expect(Units.temp(27.24, decimals: 0, withUnit: false), '27°');
      expect(Units.speed(4.9), '4.9\u{00A0}m/s');
    });

    test('imperial formatting', () {
      Units.imperial.value = true;
      expect(Units.temp(0), '32.0°F');
      expect(Units.temp(100, decimals: 0), '212°F');
      expect(Units.speed(10, decimals: 1), '22.4\u{00A0}mph');
    });
  });

  group('HeroVerdictCard', () {
    testWidgets('renders headline, percentage, window and size chips',
        (tester) async {
      _phoneSized(tester);
      await tester.pumpWidget(_wrap(const HeroVerdictCard(
        band: FlightBand.prime,
        oneInN: 7,
        dateLine: 'Today · Sat 17 Jan',
        conditionLine: 'Partly cloudy · 27°C',
        bestWindow: 'Best window 4pm–7pm',
        sizeLine: 'Likely small species',
      )));
      expect(find.text('Prime conditions'), findsOneWidget);
      expect(find.text('1 in 7'), findsOneWidget);
      expect(find.text('Best window 4pm–7pm'), findsOneWidget);
      expect(find.text('Likely small species'), findsOneWidget);
    });

    testWidgets('unlikely day hides optional chips', (tester) async {
      _phoneSized(tester);
      await tester.pumpWidget(_wrap(const HeroVerdictCard(
        band: FlightBand.noFly,
        oneInN: 99,
        dateLine: 'Today · Mon 3 Jun',
        conditionLine: 'Light rain · 12°C',
      )));
      expect(find.text('No flights today'), findsOneWidget);
      expect(find.textContaining('1 in'), findsNothing);
      expect(find.textContaining('Best window'), findsNothing);
    });
  });

  group('HourlyChart', () {
    testWidgets('renders 24 bars with Now marker and ticks', (tester) async {
      _phoneSized(tester);
      final int base = DateTime.utc(2026, 1, 17, 3).millisecondsSinceEpoch ~/ 1000;
      await tester.pumpWidget(_wrap(HourlyChart(
        points: [
          for (int i = 0; i < 24; i++) HourlyPoint(base + i * 3600, (i * 4) % 100, FlightBand.watchful),
        ],
        timezoneOffsetSeconds: 36000, // UTC+10
      )));
      expect(find.text('Now'), findsOneWidget);
      // Ticks at i=6,12,18 → local 7pm, 1am, 7am.
      expect(find.text('7pm'), findsOneWidget);
      expect(find.text('1am'), findsOneWidget);
      expect(find.text('7am'), findsOneWidget);
    });

    testWidgets('handles short hourly responses without crashing',
        (tester) async {
      _phoneSized(tester);
      await tester.pumpWidget(_wrap(HourlyChart(
        points: [for (int i = 0; i < 5; i++) HourlyPoint(1700000000 + i * 3600, 40, FlightBand.quiet)],
        timezoneOffsetSeconds: 0,
      )));
      expect(find.text('Now'), findsOneWidget);
    });
  });

  group('WeekList', () {
    testWidgets('renders a row per day with labelled verdict pills',
        (tester) async {
      _phoneSized(tester);
      await tester.pumpWidget(_wrap(const WeekList(days: [
        WeekDay(day: 'Sun', temp: '29°', wind: '5.1\u{00A0}m/s', band: FlightBand.promising, percentile: 78),
        WeekDay(day: 'Mon', temp: '31°', wind: '9.2\u{00A0}m/s', band: FlightBand.quiet, percentile: 22),
        WeekDay(day: 'Tue', temp: '28°', wind: '4.4\u{00A0}m/s', band: FlightBand.prime, percentile: 93),
        WeekDay(day: 'Wed', temp: '20°', wind: '10.0\u{00A0}m/s', band: FlightBand.noFly, percentile: 2),
        WeekDay(day: 'Thu', temp: '26°', wind: '6.7\u{00A0}m/s', band: FlightBand.watchful, percentile: 55),
        WeekDay(day: 'Fri', temp: '30°', wind: '3.8\u{00A0}m/s', band: FlightBand.prime, percentile: 96),
        WeekDay(day: 'Sat', temp: '32°', wind: '8.5\u{00A0}m/s', band: FlightBand.quiet, percentile: 30),
      ])));
      expect(find.text('Sun'), findsOneWidget);
      expect(find.text('Prime'), findsNWidgets(2));
      expect(find.text('Promising'), findsOneWidget);
      expect(find.text('No-fly'), findsOneWidget);
    });
  });

  group('WhyChipsRow', () {
    testWidgets('shows drivers and taps through', (tester) async {
      _phoneSized(tester);
      bool tapped = false;
      await tester.pumpWidget(_wrap(WhyChipsRow(
        drivers: const [
          WhyDriver(label: 'Temp 27°', direction: 1),
          WhyDriver(label: 'Wind 5\u{00A0}m/s', direction: 1),
          WhyDriver(label: 'Humidity 40%', direction: -1),
        ],
        onTap: () => tapped = true,
      )));
      expect(find.text('Why?'), findsOneWidget);
      expect(find.text('Temp 27° ↑'), findsOneWidget);
      expect(find.text('Humidity 40% ↓'), findsOneWidget);
      await tester.tap(find.text('Why?'));
      expect(tapped, isTrue);
    });
  });

  group('Report sheet', () {
    testWidgets('submitting a size returns a sighting', (tester) async {
      _phoneSized(tester);
      ReportResult? result;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3D6B4F)),
          useMaterial3: true,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () async {
                  result = await showReportSheet(context,
                      locationLabel: 'Canberra, ACT');
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Report a nuptial flight'), findsOneWidget);

      // Submit is disabled until a size is chosen.
      final FilledButton submit =
          tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Submit sighting'));
      expect(submit.onPressed, isNull);

      await tester.tap(find.text('Medium'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit sighting'));
      await tester.pumpAndSettle();
      expect(result, isNotNull);
      expect(result!.size, 'medium');
      expect(result!.sawNothing, isFalse);
    });

    testWidgets('no-flight and cancel are distinct results', (tester) async {
      _phoneSized(tester);
      ReportResult? result = const ReportResult.sighting('small');
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3D6B4F)),
          useMaterial3: true,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () async {
                  result = await showReportSheet(context,
                      locationLabel: 'Canberra, ACT');
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('I looked — no flights'));
      await tester.pumpAndSettle();
      expect(result!.sawNothing, isTrue);
      expect(result!.size, isNull);

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(result, isNull);
    });
  });
}
