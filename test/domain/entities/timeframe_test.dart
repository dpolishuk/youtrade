import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/domain/entities/timeframe.dart';

void main() {
  group('Timeframe', () {
    test('codes match mockup labels', () {
      expect(Timeframe.m1.code, '1m');
      expect(Timeframe.m5.code, '5m');
      expect(Timeframe.m15.code, '15m');
      expect(Timeframe.h1.code, '1H');
      expect(Timeframe.h4.code, '4H');
      expect(Timeframe.d1.code, '1D');
      expect(Timeframe.w1.code, '1W');
    });

    test('seconds are correct', () {
      expect(Timeframe.m1.seconds, 60);
      expect(Timeframe.m5.seconds, 300);
      expect(Timeframe.m15.seconds, 900);
      expect(Timeframe.h1.seconds, 3600);
      expect(Timeframe.h4.seconds, 14400);
      expect(Timeframe.d1.seconds, 86400);
      expect(Timeframe.w1.seconds, 604800);
    });

    test('does not include 30m', () {
      expect(Timeframe.values.map((t) => t.code), isNot(contains('30m')));
    });

    test('includes weekly timeframe', () {
      expect(Timeframe.values, contains(Timeframe.w1));
    });
  });
}
