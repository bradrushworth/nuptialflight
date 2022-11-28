import 'package:nuptialflight/controller/arangodb.dart';
import 'package:test/test.dart';

void main() {
  group('ArangoDB', () {
    test('Latest Flights', () async {
      await ArangoSingleton().getRecentFlights().then((value) {
        print(value);
        expect(value.length, greaterThanOrEqualTo(1));
      });
    });
  });
}
