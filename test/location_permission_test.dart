import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:nuptialflight/controller/weather_fetcher.dart';
import 'package:test/test.dart';

void main() {
  group('LocationPermissionGate', () {
    test('overlapping callers share one request', () async {
      // Play vitals, 2.29.1: geolocator's Android plugin keeps one result
      // callback, so a second request made while the first was pending
      // replaced it and the same reply was sent twice ("Reply already
      // submitted", a crash).
      final pending = Completer<LocationPermission>();
      var requests = 0;
      final gate = LocationPermissionGate(
        check: () async => LocationPermission.denied,
        request: () {
          requests++;
          return pending.future;
        },
      );

      final first = gate.permission();
      final second = gate.permission();
      await Future<void>.delayed(Duration.zero);
      expect(requests, 1);

      pending.complete(LocationPermission.whileInUse);
      expect(await first, LocationPermission.whileInUse);
      expect(await second, LocationPermission.whileInUse);
    });

    test('does not request a permission the app already has', () async {
      var requests = 0;
      for (final granted in [
        LocationPermission.whileInUse,
        LocationPermission.always,
      ]) {
        final gate = LocationPermissionGate(
          check: () async => granted,
          request: () async {
            requests++;
            return granted;
          },
        );
        expect(await gate.permission(), granted);
      }
      expect(requests, 0);
    });

    test('asks again once the previous request has finished', () async {
      var requests = 0;
      final gate = LocationPermissionGate(
        check: () async => LocationPermission.denied,
        request: () async {
          requests++;
          return LocationPermission.denied;
        },
      );
      expect(await gate.permission(), LocationPermission.denied);
      expect(await gate.permission(), LocationPermission.denied);
      expect(requests, 2);
    });

    test('a failed request is not reused by the next caller', () async {
      var requests = 0;
      final gate = LocationPermissionGate(
        check: () async => LocationPermission.denied,
        request: () async {
          requests++;
          if (requests == 1) throw StateError('activity missing');
          return LocationPermission.whileInUse;
        },
      );
      await expectLater(gate.permission(), throwsStateError);
      expect(await gate.permission(), LocationPermission.whileInUse);
    });

    test('without the check it always requests (web)', () async {
      // geolocator's web requestPermission is what raises the browser
      // prompt, and its checkPermission needs the Permissions API, so the
      // web build keeps requesting directly.
      var checks = 0;
      var requests = 0;
      final gate = LocationPermissionGate(
        check: () async {
          checks++;
          return LocationPermission.whileInUse;
        },
        request: () async {
          requests++;
          return LocationPermission.whileInUse;
        },
        checkFirst: false,
      );
      expect(await gate.permission(), LocationPermission.whileInUse);
      expect(checks, 0);
      expect(requests, 1);
    });
  });
}
