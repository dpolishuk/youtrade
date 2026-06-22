import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtrade/presentation/providers/portfolio_data_provider.dart';
import 'package:youtrade/presentation/theme/theme_provider.dart';

void main() {
  group('portfolioDataProvider', () {
    test('produces exact mockup values', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Initialize theme so appColorThemeProvider can resolve.
      container.read(appThemeProvider);

      final data = container.read(portfolioDataProvider);

      expect(data.netWorth, 746240.0);
      expect(data.netWorthFormatted, r'$746,240.00');
      expect(data.deltaAmount, 14820.0);
      expect(data.deltaAmountFormatted, r'+$14,820.00');
      expect(data.deltaPercent, '+2.04%');
      expect(data.venueCount, 4);
      expect(data.assetMix, 'Spot 41 · Perp 38 · Eq 12 · Fut 6 · Opt 3');
      expect(data.equityCurve.length, 90);
      expect(data.equityCurve.first, closeTo(812468.7068931296, 1e-9));

      expect(data.exchanges.length, 4);
      expect(data.exchanges[0].value, r'$312,480');
      expect(data.exchanges[0].percentChange, 2.14);
      expect(data.exchanges[1].value, r'$198,320');
      expect(data.exchanges[1].percentChange, -0.86);
      expect(data.exchanges[2].value, r'$146,900');
      expect(data.exchanges[2].percentChange, 1.42);
      expect(data.exchanges[3].value, r'$88,540');
      expect(data.exchanges[3].percentChange, 0.31);

      expect(data.positions.length, 4);
      expect(data.positions[0].symbol, 'BTCUSDT');
      expect(data.positions[0].value, r'$107,320');
      expect(data.positions[0].pnl, r'+$4,210');
      expect(data.positions[3].symbol, 'GC=F');
      expect(data.positions[3].side, 'SHORT');
    });
  });
}
