import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/domain/entities/venue.dart';
import 'package:youtrade/presentation/providers/market_screener_provider.dart';

void main() {
  group('MarketScreenerItem row', () {
    test(
      'fills missing change24hPercent from ticker when price is provided',
      () {
        final item = row(
          rawSymbol: 'BTCUSDT',
          name: 'Bitcoin',
          venue: Venue.binance,
          assetClass: AssetClass.perp,
          decimals: 1,
          price: 65000.0,
        );

        expect(item.price, 65000.0);
        expect(item.change24hPercent, closeTo(6.423290746323324, 1e-9));
      },
    );

    test(
      'fills missing price from ticker when change24hPercent is provided',
      () {
        final item = row(
          rawSymbol: 'ETHUSDT',
          name: 'Ethereum',
          venue: Venue.bybit,
          assetClass: AssetClass.perp,
          decimals: 2,
          change24hPercent: 2.5,
        );

        expect(item.price, closeTo(2887.8860130257644, 1e-9));
        expect(item.change24hPercent, 2.5);
      },
    );

    test(
      'falls back to ticker when both price and change24hPercent are null',
      () {
        final item = row(
          rawSymbol: 'BTCUSDT',
          name: 'Bitcoin',
          venue: Venue.binance,
          assetClass: AssetClass.perp,
          decimals: 1,
        );

        expect(item.price, closeTo(105154.04697406417, 1e-9));
        expect(item.change24hPercent, closeTo(6.423290746323324, 1e-9));
      },
    );

    test('uses provided price and change24hPercent when both are given', () {
      final item = row(
        rawSymbol: 'SOLUSDT',
        name: 'Solana',
        venue: Venue.okx,
        assetClass: AssetClass.spot,
        decimals: 2,
        price: 150.0,
        change24hPercent: -1.2,
      );

      expect(item.price, 150.0);
      expect(item.change24hPercent, -1.2);
    });
  });
}
