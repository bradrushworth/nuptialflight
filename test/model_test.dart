import 'package:nuptialflight/models/final_model.dart';
import 'package:test/test.dart';

void main() {
  group('Daily Model', () {
    test('Score', () {
      expect(
          score([-35.2, 149.1, 16.4, 5.7, 0.95, 77, 74, 1013, 12.0, 38])[1], closeTo(0.42, 0.01));
    });
  });
}
