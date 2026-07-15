import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/ui/widgets/trading_terminal/formatting.dart';

void main() {
  group('formatPriceSmart', () {
    test('large price uses two decimals with grouping', () {
      expect(formatPriceSmart(64708.60), '64,708.60');
    });

    test('small price is never collapsed to "0.00"', () {
      final result = formatPriceSmart(0.0006789);
      expect(result, isNot('0.00'));
      expect(result, '0.000679');
    });

    test('tiny price shows at least eight decimals', () {
      final result = formatPriceSmart(0.000012345);
      expect(result, '0.00001235');
      final dot = result.indexOf('.');
      expect(result.length - dot - 1, greaterThanOrEqualTo(8));
    });

    test('zero formats as "0.00"', () {
      expect(formatPriceSmart(0), '0.00');
    });

    test('unit-magnitude price keeps four decimals', () {
      expect(formatPriceSmart(1.2345), '1.2345');
    });

    test('preserves negative sign', () {
      expect(formatPriceSmart(-0.0006789), '-0.000679');
    });
  });
}
