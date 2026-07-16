import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:youtrade/data/datasources/remote/bybit/bybit_account_client.dart';
import 'package:youtrade/domain/entities/account_position.dart';
import 'package:youtrade/domain/entities/account_wallet_balance.dart';
import 'package:youtrade/presentation/providers/portfolio_data_provider.dart';
import 'package:youtrade/presentation/theme/theme_provider.dart';

void main() {
  group('baseAsset', () {
    test('strips USDT suffix', () {
      expect(baseAsset('BTCUSDT'), 'BTC');
      expect(baseAsset('ETHUSDT'), 'ETH');
    });

    test('strips USD suffix', () {
      expect(baseAsset('BTCUSD'), 'BTC');
    });

    test('returns symbol unchanged when no known quote suffix', () {
      expect(baseAsset('FOOBAR'), 'FOOBAR');
    });
  });

  group('buildPortfolioData', () {
    final accent = const Color(0xFF00E6D2);

    test('maps wallet coins to exchange cards with equity values', () {
      final wallet = WalletBalance(
        accountType: 'UNIFIED',
        totalEquity: 10000.0,
        coins: [
          WalletCoin(coin: 'USDT', walletBalance: 8000.0, equity: 8000.0),
          WalletCoin(coin: 'BTC', walletBalance: 0.03, equity: 2000.0),
        ],
      );

      final data = buildPortfolioData(
        wallet: wallet,
        positions: const [],
        accent: accent,
      );

      expect(data.needsCredentials, isFalse);
      expect(data.netWorth, 10000.0);
      expect(data.netWorthFormatted, r'$10,000.00');
      expect(data.exchanges.length, 2);
      expect(data.exchanges[0].name, 'USDT');
      expect(data.exchanges[0].value, r'$8,000');
      expect(data.exchanges[1].name, 'BTC');
      expect(data.exchanges[1].value, r'$2,000');
    });

    test(
      'maps wallet coins to allocation segments with proportional shares',
      () {
        final wallet = WalletBalance(
          accountType: 'UNIFIED',
          totalEquity: 10000.0,
          coins: [
            WalletCoin(coin: 'USDT', walletBalance: 8000.0, equity: 8000.0),
            WalletCoin(coin: 'BTC', walletBalance: 0.03, equity: 2000.0),
          ],
        );

        final data = buildPortfolioData(
          wallet: wallet,
          positions: const [],
          accent: accent,
        );

        expect(data.allocationSegments.length, 2);
        expect(data.allocationSegments[0].label, 'USDT');
        expect(data.allocationSegments[0].share, closeTo(80.0, 1e-9));
        expect(data.allocationSegments[1].label, 'BTC');
        expect(data.allocationSegments[1].share, closeTo(20.0, 1e-9));
      },
    );

    test('maps positions to Position list with side, pnl and qty', () {
      final wallet = WalletBalance(
        accountType: 'UNIFIED',
        totalEquity: 50000.0,
        coins: [
          WalletCoin(coin: 'USDT', walletBalance: 50000.0, equity: 50000.0),
        ],
      );
      final positions = [
        AccountPosition(
          symbol: 'BTCUSDT',
          side: 'Buy',
          size: 0.5,
          unrealisedPnl: 1200.0,
        ),
        AccountPosition(
          symbol: 'ETHUSDT',
          side: 'Sell',
          size: 3.0,
          unrealisedPnl: -500.0,
        ),
      ];

      final data = buildPortfolioData(
        wallet: wallet,
        positions: positions,
        accent: accent,
      );

      expect(data.positions.length, 2);
      expect(data.positions[0].symbol, 'BTCUSDT');
      expect(data.positions[0].side, 'LONG');
      expect(data.positions[0].pnl, r'+$1,200.00');
      expect(data.positions[1].symbol, 'ETHUSDT');
      expect(data.positions[1].side, 'SHORT');
      expect(data.positions[1].pnl, r'-$500.00');
    });

    test('computes delta from sum of unrealised PnL', () {
      final wallet = WalletBalance(
        accountType: 'UNIFIED',
        totalEquity: 50000.0,
        coins: [
          WalletCoin(coin: 'USDT', walletBalance: 50000.0, equity: 50000.0),
        ],
      );
      final positions = [
        AccountPosition(
          symbol: 'BTCUSDT',
          side: 'Buy',
          size: 0.5,
          unrealisedPnl: 1200.0,
        ),
        AccountPosition(
          symbol: 'ETHUSDT',
          side: 'Sell',
          size: 3.0,
          unrealisedPnl: -500.0,
        ),
      ];

      final data = buildPortfolioData(
        wallet: wallet,
        positions: positions,
        accent: accent,
      );

      expect(data.deltaAmount, 700.0);
      expect(data.deltaAmountFormatted, r'+$700.00');
    });

    test('handles empty wallet with zero balance gracefully', () {
      final wallet = WalletBalance(
        accountType: 'UNIFIED',
        totalEquity: 0.0,
        coins: const [],
      );

      final data = buildPortfolioData(
        wallet: wallet,
        positions: const [],
        accent: accent,
      );

      expect(data.netWorth, 0.0);
      expect(data.netWorthFormatted, r'$0.00');
      expect(data.exchanges, isEmpty);
      expect(data.allocationSegments, isEmpty);
      expect(data.positions, isEmpty);
      expect(data.deltaAmount, 0.0);
      expect(data.venueCount, 0);
    });

    test('handles empty positions list', () {
      final wallet = WalletBalance(
        accountType: 'UNIFIED',
        totalEquity: 10000.0,
        coins: [
          WalletCoin(coin: 'USDT', walletBalance: 10000.0, equity: 10000.0),
        ],
      );

      final data = buildPortfolioData(
        wallet: wallet,
        positions: const [],
        accent: accent,
      );

      expect(data.positions, isEmpty);
      expect(data.deltaAmount, 0.0);
    });

    test('builds asset mix from coin symbols', () {
      final wallet = WalletBalance(
        accountType: 'UNIFIED',
        totalEquity: 10000.0,
        coins: [
          WalletCoin(coin: 'USDT', walletBalance: 8000.0, equity: 8000.0),
          WalletCoin(coin: 'BTC', walletBalance: 0.03, equity: 2000.0),
        ],
      );

      final data = buildPortfolioData(
        wallet: wallet,
        positions: const [],
        accent: accent,
      );

      expect(data.assetMix, 'USDT · BTC');
    });
  });

  group('portfolioDataProvider', () {
    BybitAccountClient clientWithResponses({
      required Map<String, dynamic> walletResponse,
      required Map<String, dynamic> positionsResponse,
    }) {
      return BybitAccountClient(
        apiKey: 'test-key',
        apiSecret: 'test-secret',
        httpClient: MockClient((request) async {
          final path = request.url.path;
          if (path.contains('/v5/account/wallet-balance')) {
            return http.Response(jsonEncode(walletResponse), 200);
          }
          if (path.contains('/v5/position/list')) {
            return http.Response(jsonEncode(positionsResponse), 200);
          }
          return http.Response('{"retCode":1,"retMsg":"unknown"}', 200);
        }),
      );
    }

    Map<String, dynamic> walletJson({
      required double totalEquity,
      List<Map<String, dynamic>> coins = const [],
    }) {
      return {
        'retCode': 0,
        'retMsg': 'OK',
        'result': {
          'list': [
            {
              'accountType': 'UNIFIED',
              'totalEquity': totalEquity.toString(),
              'coin': coins,
            },
          ],
        },
      };
    }

    Map<String, dynamic> positionsJson(List<Map<String, dynamic>> positions) {
      return {
        'retCode': 0,
        'retMsg': 'OK',
        'result': {'category': 'linear', 'list': positions},
      };
    }

    test('is in loading state initially', () async {
      final pendingClient = BybitAccountClient(
        apiKey: 'test-key',
        apiSecret: 'test-secret',
        httpClient: MockClient((request) => Completer<http.Response>().future),
      );
      final container = ProviderContainer(
        overrides: [
          bybitHasCredentialsProvider.overrideWithValue(true),
          bybitAccountClientProvider.overrideWithValue(pendingClient),
        ],
      );
      addTearDown(container.dispose);

      // Initialize theme so appColorThemeProvider can resolve.
      container.read(appThemeProvider);

      final asyncValue = container.read(portfolioDataProvider);
      expect(asyncValue.isLoading, isTrue);
    });

    test('returns needsCredentials state when credentials missing', () async {
      final container = ProviderContainer(
        overrides: [bybitHasCredentialsProvider.overrideWithValue(false)],
      );
      addTearDown(container.dispose);

      final data = await container.read(portfolioDataProvider.future);

      expect(data.needsCredentials, isTrue);
    });

    test(
      'fetches wallet balance and positions and builds PortfolioData',
      () async {
        final client = clientWithResponses(
          walletResponse: walletJson(
            totalEquity: 10000.0,
            coins: [
              {'coin': 'USDT', 'walletBalance': '8000.0', 'equity': '8000.0'},
              {'coin': 'BTC', 'walletBalance': '0.03', 'equity': '2000.0'},
            ],
          ),
          positionsResponse: positionsJson([
            {
              'symbol': 'BTCUSDT',
              'side': 'Buy',
              'size': '0.5',
              'unrealisedPnl': '1200.0',
            },
          ]),
        );

        final container = ProviderContainer(
          overrides: [
            bybitHasCredentialsProvider.overrideWithValue(true),
            bybitAccountClientProvider.overrideWithValue(client),
          ],
        );
        addTearDown(container.dispose);

        final data = await container.read(portfolioDataProvider.future);

        expect(data.needsCredentials, isFalse);
        expect(data.netWorth, 10000.0);
        expect(data.exchanges.length, 2);
        expect(data.positions.length, 1);
        expect(data.positions.first.symbol, 'BTCUSDT');
      },
    );

    test('returns zero balance gracefully when wallet has no coins', () async {
      final client = clientWithResponses(
        walletResponse: walletJson(totalEquity: 0.0, coins: const []),
        positionsResponse: positionsJson(const []),
      );

      final container = ProviderContainer(
        overrides: [
          bybitHasCredentialsProvider.overrideWithValue(true),
          bybitAccountClientProvider.overrideWithValue(client),
        ],
      );
      addTearDown(container.dispose);

      final data = await container.read(portfolioDataProvider.future);

      expect(data.netWorth, 0.0);
      expect(data.exchanges, isEmpty);
      expect(data.positions, isEmpty);
    });

    test('throws when wallet balance API returns an error', () async {
      final client = clientWithResponses(
        walletResponse: {'retCode': 10001, 'retMsg': 'error', 'result': {}},
        positionsResponse: positionsJson(const []),
      );

      final container = ProviderContainer(
        overrides: [
          bybitHasCredentialsProvider.overrideWithValue(true),
          bybitAccountClientProvider.overrideWithValue(client),
        ],
      );
      addTearDown(container.dispose);

      expect(
        () => container.read(portfolioDataProvider.future),
        throwsException,
      );
    });
  });
}
