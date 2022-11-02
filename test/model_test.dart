import 'package:nuptialflight/models/final_model.dart';
import 'package:test/test.dart';

void main() {
  group('Model', () {
    test('Temperature', () {
      expect(
          score([-35.2, 16.4, 7.1, 77, 74, 1013, 6.1])[1], closeTo(0.86, 0.01));
    });
  });
}
