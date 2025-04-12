import 'package:nuptialflight/controller/arangodb.dart';
import 'package:test/test.dart';

void main() {
  group('ArangoDB', () {
    test('Latest Flights', () async {
      await ArangoSingleton().getRecentFlights().then((value) {
        //print(value);
        // Temporarily disabled due to broken API last 48 hours
        // expect(value.length, greaterThanOrEqualTo(1));
        // expect(value.first['key'], isNotEmpty);
        // expect(value.first['weather'], isNotEmpty);
        // expect(value.first['size'], isNotEmpty);
        // expect(value.first['lat'], inInclusiveRange(-180, 180));
        // expect(value.first['lon'], inInclusiveRange(-180, 180));
      });
    });
  });
}
