import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuptialflight/controller/app_language.dart';
import 'package:nuptialflight/l10n/app_localizations.dart';
import 'package:nuptialflight/main.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppLanguage.selected.value = null;
  });

  test('loads a saved language and ignores unsupported saved codes', () async {
    SharedPreferences.setMockInitialValues({'app_language': 'en'});
    await AppLanguage.load();
    expect(AppLanguage.selected.value, const Locale('en'));

    SharedPreferences.setMockInitialValues({'app_language': 'da'});
    await AppLanguage.load();
    expect(AppLanguage.selected.value, isNull);
  });

  test('selection persists and system option removes override', () async {
    await AppLanguage.choose(const Locale('fr'));
    expect(AppLanguage.selected.value, const Locale('fr'));
    expect(
      (await SharedPreferences.getInstance()).getString('app_language'),
      'fr',
    );
    expect(await AppLanguage.savedLocale(), const Locale('fr'));

    await AppLanguage.choose(null);
    expect(AppLanguage.selected.value, isNull);
    expect(
      (await SharedPreferences.getInstance()).containsKey('app_language'),
      isFalse,
    );
  });

  testWidgets('saved override changes MaterialApp localization immediately', (
    tester,
  ) async {
    await tester.pumpWidget(
      ValueListenableBuilder<Locale?>(
        valueListenable: AppLanguage.selected,
        builder: (context, selected, _) => MaterialApp(
          locale: selected,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) =>
                Text(AppLocalizations.of(context)!.menuLanguage),
          ),
        ),
      ),
    );
    await AppLanguage.choose(const Locale('de'));
    await tester.pumpAndSettle();
    expect(find.text('Sprache'), findsOneWidget);
    await AppLanguage.choose(const Locale('en'));
    await tester.pumpAndSettle();
    expect(find.text('Language'), findsOneWidget);
  });

  testWidgets('German menu can switch the app to English', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    PackageInfo.setMockInitialValues(
      installerStore: 'test',
      appName: 'Ant Flight',
      packageName: 'au.com.bitbot.nuptialflight',
      version: '2.28.1',
      buildNumber: '162',
      buildSignature: 'test',
    );
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    AppLanguage.selected.value = const Locale('de');
    await tester.pumpWidget(MyMaterialApp());
    await tester.pump();
    await tester.tap(find.byTooltip('Weitere Optionen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Sprache').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('English'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(AppLanguage.selected.value, const Locale('en'));
    expect(find.byTooltip('More options'), findsOneWidget);
  });
}
