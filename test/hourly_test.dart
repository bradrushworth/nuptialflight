import 'package:nuptialflight/models/hour_model.dart';
import 'package:test/test.dart';

void main() {
  group('Hour Model', () {
    test('Score', () {
      expect(
          score([-35.2, 149.1, 11, 5.7, 194, 0.65, 77, 74, 1015, 12.0, 38])[1], closeTo(0.38, 0.01));
    });
  });
}
