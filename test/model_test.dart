import 'package:nuptialflight/models/final_model.dart';
import 'package:test/test.dart';

void main() {
  group('Model', () {
    test('Temperature', () {
      expect(
          //score([-35.2, 16.4, 5.7, 77, 74, 1013, 6.1])[1], closeTo(0.91, 0.01));
          score([-35.2, 0.992021, 1.0, 1.0, 0.89393, 0.94631])[1],
          closeTo(1.00, 0.01));
    });
  });
}
