import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nuptialflight/controller/report_api.dart';

const install = '123e4567-e89b-42d3-a456-426614174000';

void main() {
  late Map<String, dynamic> fixture;
  setUpAll(() {
    fixture =
        jsonDecode(File('test/fixtures/api_contract.json').readAsStringSync())
            as Map<String, dynamic>;
  });

  test('no-flight fixture carries an explicit null size', () {
    final request = fixture['no_flight_request'] as Map<String, dynamic>;
    expect(request.containsKey('size'), isTrue);
    expect(request['size'], isNull);
    final sighting = fixture['sighting_request'] as Map<String, dynamic>;
    expect({...request}..remove('size'), {...sighting}..remove('size'));

    final stored = fixture['expected_stored_no_flight'] as Map<String, dynamic>;
    expect(stored.keys, fixture['expected_stored'].keys);
    for (final name in ['flights', 'historical', 'current']) {
      final doc = stored[name] as Map<String, dynamic>;
      expect(doc['flight'], 'unknown');
      expect(doc.containsKey('size'), isTrue);
      expect(doc['size'], isNull);
    }
    final leadup = stored['leadup'] as Map<String, dynamic>;
    expect(leadup['flight'], 'unknown');
    expect(leadup.containsKey('size'), isFalse);
  });

  test(
    'confirmSighting sends the no-flight fixture with its null size',
    () async {
      final requests = <http.Request>[];
      final api = ApiClient(
        baseUrl: 'https://example.test/nuptialflight/v1',
        apiKey: 'test-key',
        httpClient: MockClient((request) async {
          requests.add(request);
          return http.Response('{"handle":"signed"}', 200);
        }),
        installId: () async => install,
        retryDelay: Duration.zero,
        timeout: const Duration(milliseconds: 100),
      );
      expect(
        await api.confirmSighting('signed', fixture['no_flight_request']),
        isTrue,
      );
      final sent = jsonDecode(requests.single.body) as Map<String, dynamic>;
      expect(sent.containsKey('size'), isTrue);
      expect(sent, fixture['no_flight_request']);
    },
  );
}
