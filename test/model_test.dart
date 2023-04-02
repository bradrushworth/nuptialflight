import 'package:nuptialflight/models/final_model.dart';
import 'package:test/test.dart';

void main() {
  group('Model', () {
    test('Temperature', () {
      expect(
          //score([-35.2, 149.1, 16.4, 5.7, 77, 74, 1013, 0.0, 38])[1], closeTo(0.97, 0.01));
          score([-35.2, 149.1, 5.7, 77, 74, 1013, 12.0, 38])[1], closeTo(0.86, 0.01));
    });
  });
}
