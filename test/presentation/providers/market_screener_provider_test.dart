import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:youtrade/data/datasources/remote/bybit/bybit_rest_client.dart';
import 'package:youtrade/domain/entities/venue.dart';
import 'package:youtrade/presentation/providers/market_screener_provider.dart';

void main() {
  group('tickerToScreenerItem', () {
    test('maps linear ticker to perp screener item', () {
      final item = tickerToScreenerItem({
        'symbol': 'BTCUSDT',
        'lastPrice': '65000.5',
        'price24hPcnt': '0.0523',
        'volume24h': '1000000.0',
      }, AssetClass.perp);

      expect(item.rawSymbol, 'BTCUSDT');
      expect(item.symbol, 'BTC');
      expect(item.name, 'BTCUSDT');
      expect(item.venue, Venue.bybit);
      expect(item.assetClass, AssetClass.perp);
      expect(item.price, 65000.5);
      expect(item.change24hPercent, closeTo(5.23, 1e-9));
      expect(item.volume24h, 1000000.0);
    });

    test('maps spot ticker to spot screener item', () {
      final item = tickerToScreenerItem({
        'symbol': 'SOLUSDT',
        'lastPrice': '150.25',
        'price24hPcnt': '-0.0142',
        'volume24h': '200000.0',
      }, AssetClass.spot);

      expect(item.assetClass, AssetClass.spot);
      expect(item.symbol, 'SOL');
      expect(item.price, 150.25);
      expect(item.change24hPercent, closeTo(-1.42, 1e-9));
    });

    test('handles negative price24hPcnt', () {
      final item = tickerToScreenerItem({
        'symbol': 'ETHUSDT',
        'lastPrice': '3200.0',
        'price24hPcnt': '-0.0234',
        'volume24h': '500000.0',
      }, AssetClass.perp);

      expect(item.change24hPercent, closeTo(-2.34, 1e-9));
    });

    test('defaults to zero when fields are missing or unparseable', () {
      final item = tickerToScreenerItem(<String, dynamic>{}, AssetClass.perp);

      expect(item.price, 0.0);
      expect(item.change24hPercent, 0.0);
      expect(item.volume24h, 0.0);
      expect(item.compositeScore, 0.0);
    });

    test('parses all extended ticker fields', () {
      final item = tickerToScreenerItem({
        'symbol': 'BTCUSDT',
        'lastPrice': '65000.0',
        'price24hPcnt': '0.05',
        'volume24h': '1000.0',
        'turnover24h': '5000000.0',
        'highPrice24h': '66000.0',
        'lowPrice24h': '64000.0',
        'prevPrice24h': '64500.0',
        'openInterestValue': '50000000.0',
        'fundingRate': '0.0001',
        'bid1Price': '64999.0',
        'ask1Price': '65001.0',
        'markPrice': '65000.5',
        'indexPrice': '65000.2',
      }, AssetClass.perp);

      expect(item.highPrice24h, 66000.0);
      expect(item.lowPrice24h, 64000.0);
      expect(item.prevPrice24h, 64500.0);
      expect(item.openInterestValue, 5e7);
      expect(item.fundingRate, closeTo(0.0001, 1e-9));
      expect(item.bid1Price, 64999.0);
      expect(item.ask1Price, 65001.0);
      expect(item.markPrice, 65000.5);
      expect(item.indexPrice, 65000.2);
    });

    test('accepts compositeScore parameter', () {
      final item = tickerToScreenerItem(
        {'symbol': 'BTCUSDT', 'lastPrice': '65000.0'},
        AssetClass.perp,
        compositeScore: 1.5,
      );

      expect(item.compositeScore, 1.5);
    });
  });

  group('displaySymbol', () {
    test('strips trailing USDT suffix', () {
      expect(displaySymbol('BTCUSDT'), 'BTC');
      expect(displaySymbol('ETHUSDT'), 'ETH');
    });

    test('returns symbol unchanged when no USDT suffix', () {
      expect(displaySymbol('BTC'), 'BTC');
      expect(displaySymbol('BTCUSDC'), 'BTCUSDC');
    });
  });

  group('priceDecimals', () {
    test('uses 1 decimal for prices >= 10000', () {
      expect(priceDecimals(105000.0), 1);
    });

    test('uses 2 decimals for prices >= 1', () {
      expect(priceDecimals(3200.0), 2);
      expect(priceDecimals(150.0), 2);
      expect(priceDecimals(1.0), 2);
    });

    test('uses 4 decimals for prices >= 0.01', () {
      expect(priceDecimals(0.5), 4);
      expect(priceDecimals(0.01), 4);
    });

    test('uses 6 decimals for very small prices', () {
      expect(priceDecimals(0.001), 6);
    });
  });

  group('marketScreenerItemsProvider', () {
    BybitRestClient clientWithMockResponse(
      String Function(String category) responseBody,
    ) {
      return BybitRestClient(
        httpClient: MockClient((request) async {
          final category = request.url.queryParameters['category'] ?? '';
          return http.Response(responseBody(category), 200);
        }),
      );
    }

    String tickersJson(String category, List<Map<String, String>> tickers) {
      return jsonEncode({
        'retCode': 0,
        'retMsg': 'OK',
        'result': {'category': category, 'list': tickers},
      });
    }

    test('fetches and combines linear and spot tickers', () async {
      final client = clientWithMockResponse(
        (category) => tickersJson(
          category,
          category == 'linear'
              ? [
                  {
                    'symbol': 'BTCUSDT',
                    'lastPrice': '65000.0',
                    'price24hPcnt': '0.05',
                    'volume24h': '1000.0',
                  },
                  {
                    'symbol': 'ETHUSDT',
                    'lastPrice': '3200.0',
                    'price24hPcnt': '-0.02',
                    'volume24h': '500.0',
                  },
                ]
              : [
                  {
                    'symbol': 'SOLUSDT',
                    'lastPrice': '150.0',
                    'price24hPcnt': '0.03',
                    'volume24h': '200.0',
                  },
                ],
        ),
      );

      final container = ProviderContainer(
        overrides: [
          marketScreenerBybitClientProvider.overrideWithValue(client),
        ],
      );
      addTearDown(container.dispose);

      final items = await container.read(marketScreenerItemsProvider.future);

      expect(items.length, 3);
      final perps = items
          .where((i) => i.assetClass == AssetClass.perp)
          .toList();
      final spots = items
          .where((i) => i.assetClass == AssetClass.spot)
          .toList();
      expect(perps.length, 2);
      expect(spots.length, 1);
      expect(perps.every((i) => i.venue == Venue.bybit), isTrue);
      expect(spots.every((i) => i.venue == Venue.bybit), isTrue);
    });

    test('returns partial data when one category fails', () async {
      final client = clientWithMockResponse(
        (category) => category == 'linear'
            ? tickersJson('linear', [
                {
                  'symbol': 'BTCUSDT',
                  'lastPrice': '65000.0',
                  'price24hPcnt': '0.05',
                  'volume24h': '1000.0',
                },
              ])
            : '{"retCode":10001,"retMsg":"error","result":{}}',
      );

      final container = ProviderContainer(
        overrides: [
          marketScreenerBybitClientProvider.overrideWithValue(client),
        ],
      );
      addTearDown(container.dispose);

      final items = await container.read(marketScreenerItemsProvider.future);

      expect(items.length, 1);
      expect(items.first.rawSymbol, 'BTCUSDT');
    });

    test('throws when both categories fail', () async {
      final client = clientWithMockResponse(
        (_) => '{"retCode":10001,"retMsg":"error","result":{}}',
      );

      final container = ProviderContainer(
        overrides: [
          marketScreenerBybitClientProvider.overrideWithValue(client),
        ],
      );
      addTearDown(container.dispose);

      expect(
        () => container.read(marketScreenerItemsProvider.future),
        throwsA(isA<Exception>()),
      );
    });

    test('sorts by composite score, not raw turnover', () async {
      // Three perps: BTCLIKE (best liquidity/volatility), ETHLIKE (weaker),
      // and ILLIQUID (huge turnover but no OI → fails guard rails → score 0).
      final client = clientWithMockResponse(
        (category) => category == 'linear'
            ? tickersJson('linear', [
                {
                  'symbol': 'BTCLIKE',
                  'lastPrice': '65000.0',
                  'price24hPcnt': '0.05',
                  'turnover24h': '5000000000.0',
                  'openInterestValue': '50000000.0',
                  'bid1Price': '64999.5',
                  'ask1Price': '65000.5',
                  'highPrice24h': '66000.0',
                  'lowPrice24h': '64000.0',
                  'prevPrice24h': '65000.0',
                  'fundingRate': '0.0001',
                },
                {
                  'symbol': 'ETHLIKE',
                  'lastPrice': '3200.0',
                  'price24hPcnt': '0.03',
                  'turnover24h': '2000000000.0',
                  'openInterestValue': '20000000.0',
                  'bid1Price': '3199.5',
                  'ask1Price': '3200.5',
                  'highPrice24h': '3300.0',
                  'lowPrice24h': '3100.0',
                  'prevPrice24h': '3200.0',
                  'fundingRate': '0.00005',
                },
                {
                  'symbol': 'ILLIQUIDUSDT',
                  'lastPrice': '0.01',
                  'price24hPcnt': '0.5',
                  'turnover24h': '99999999999.0',
                  'openInterestValue': '0.0',
                },
              ])
            : tickersJson('spot', []),
      );

      final container = ProviderContainer(
        overrides: [
          marketScreenerBybitClientProvider.overrideWithValue(client),
        ],
      );
      addTearDown(container.dispose);

      final items = await container.read(marketScreenerItemsProvider.future);

      final btc = items.firstWhere((i) => i.rawSymbol == 'BTCLIKE');
      final eth = items.firstWhere((i) => i.rawSymbol == 'ETHLIKE');
      final illiquid = items.firstWhere((i) => i.rawSymbol == 'ILLIQUIDUSDT');

      // BTCLIKE (higher liquidity, tighter spread) out-scores ETHLIKE.
      expect(btc.compositeScore, greaterThan(eth.compositeScore));
      // BTCLIKE has a positive composite score.
      expect(btc.compositeScore, greaterThan(0.0));
      // Illiquid ticker fails guard rails → score 0.
      expect(illiquid.compositeScore, 0.0);
      // Highest-scoring item sorts first.
      expect(items.first.rawSymbol, 'BTCLIKE');
    });
  });

  group('filteredMarketScreenerItemsProvider', () {
    BybitRestClient singlePairClient() {
      return BybitRestClient(
        httpClient: MockClient((request) async {
          final category = request.url.queryParameters['category'] ?? '';
          return http.Response(
            jsonEncode({
              'retCode': 0,
              'result': {
                'category': category,
                'list': category == 'linear'
                    ? [
                        {
                          'symbol': 'BTCUSDT',
                          'lastPrice': '65000.0',
                          'price24hPcnt': '0.05',
                          'volume24h': '1000.0',
                        },
                      ]
                    : [
                        {
                          'symbol': 'SOLUSDT',
                          'lastPrice': '150.0',
                          'price24hPcnt': '0.03',
                          'volume24h': '200.0',
                        },
                      ],
              },
            }),
            200,
          );
        }),
      );
    }

    test('filters by search query on data', () async {
      final container = ProviderContainer(
        overrides: [
          marketScreenerBybitClientProvider.overrideWithValue(
            singlePairClient(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(marketScreenerItemsProvider.future);
      container.read(marketScreenerSearchProvider.notifier).state = 'btc';

      final asyncValue = container.read(filteredMarketScreenerItemsProvider);
      final markets = asyncValue.valueOrNull!;

      expect(markets.length, 1);
      expect(markets.first.rawSymbol, 'BTCUSDT');
    });

    test('filters by category on data', () async {
      final container = ProviderContainer(
        overrides: [
          marketScreenerBybitClientProvider.overrideWithValue(
            singlePairClient(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(marketScreenerItemsProvider.future);
      container.read(marketScreenerFilterProvider.notifier).state =
          MarketCategory.perp;

      final asyncValue = container.read(filteredMarketScreenerItemsProvider);
      final markets = asyncValue.valueOrNull!;

      expect(markets.length, 1);
      expect(
        markets.every((m) => m.assetClass.category == MarketCategory.perp),
        isTrue,
      );
    });

    test('returns loading state initially', () {
      final container = ProviderContainer(
        overrides: [
          marketScreenerBybitClientProvider.overrideWithValue(
            singlePairClient(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final asyncValue = container.read(filteredMarketScreenerItemsProvider);
      expect(asyncValue.isLoading, isTrue);
    });
  });
}
