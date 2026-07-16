import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:youtrade/presentation/theme/theme_provider.dart';
import 'package:youtrade/ui/screens/portfolio_screen.dart';
import 'package:youtrade/ui/widgets/portfolio/allocation_bar.dart';
import 'package:youtrade/ui/widgets/portfolio/exchange_card.dart';
import 'package:youtrade/ui/widgets/portfolio/position_tile.dart';

void main() {
  group('PortfolioScreen', () {
    GoRouter buildRouter() {
      return GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const PortfolioScreen(),
          ),
          GoRoute(
            path: '/orders',
            builder: (context, state) => const Scaffold(body: Text('Orders')),
          ),
          GoRoute(
            path: '/markets/exchange/:id',
            builder: (context, state) {
              return Scaffold(
                body: Text('Exchange ${state.pathParameters['id']}'),
              );
            },
          ),
          GoRoute(
            path: '/trading',
            builder: (context, state) {
              return Scaffold(
                body: Text('Trading ${state.uri.queryParameters['symbol']}'),
              );
            },
          ),
        ],
      );
    }

    Widget buildScreen() {
      return ProviderScope(
        child: Consumer(
          builder: (context, ref, child) {
            final theme = ref.watch(appThemeProvider);
            return MaterialApp.router(
              theme: theme,
              routerConfig: buildRouter(),
            );
          },
        ),
      );
    }

    testWidgets('renders total equity and 24h delta without overflow', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('AGGREGATED NET WORTH · 4 VENUES'), findsOneWidget);
      expect(find.textContaining(r'$746,240.00'), findsOneWidget);
      expect(find.text(r'+$14,820.00'), findsOneWidget);
      expect(find.text('+2.04%'), findsOneWidget);
      expect(find.text('24h'), findsOneWidget);

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('shows allocation bar and exchange cards', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byType(AllocationBar), findsOneWidget);
      expect(find.byType(ExchangeCard), findsNWidgets(4));

      expect(find.text('ALLOCATION BY VENUE'), findsOneWidget);
      expect(
        find.text('Spot 41 · Perp 38 · Eq 12 · Fut 6 · Opt 3'),
        findsOneWidget,
      );

      expect(find.text('Binance'), findsOneWidget);
      expect(find.text('Bybit'), findsOneWidget);
      expect(find.text('OKX'), findsOneWidget);
      expect(find.text('Coinbase'), findsOneWidget);

      expect(find.text('Spot · Perp · Options'), findsNWidgets(2));
      expect(find.text('Perp · Spot'), findsOneWidget);
      expect(find.text('Spot · Stocks'), findsOneWidget);

      expect(find.text(r'$312,480'), findsOneWidget);
      expect(find.text(r'$198,320'), findsOneWidget);
      expect(find.text(r'$146,900'), findsOneWidget);
      expect(find.text(r'$88,540'), findsOneWidget);

      expect(find.text('+2.14%'), findsOneWidget);
      expect(find.text('-0.86%'), findsOneWidget);
      expect(find.text('+1.42%'), findsOneWidget);
      expect(find.text('+0.31%'), findsOneWidget);
    });

    testWidgets('shows open positions list with exact position details', (
      tester,
    ) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('OPEN POSITIONS'), findsOneWidget);
      expect(find.text('Orders →'), findsOneWidget);
      expect(find.byType(PositionTile), findsNWidgets(4));

      expect(find.text('BTCUSDT'), findsOneWidget);
      expect(find.text('ETHUSDT'), findsOneWidget);
      expect(find.text('AAPL'), findsOneWidget);
      expect(find.text('GC=F'), findsOneWidget);

      expect(find.text('LONG'), findsNWidgets(3));
      expect(find.text('SHORT'), findsOneWidget);

      expect(find.text('Binance Perp · 1.84 BTC'), findsOneWidget);
      expect(find.text('Bybit Perp · 22.5 ETH'), findsOneWidget);
      expect(find.text('Coinbase · 120 sh'), findsOneWidget);
      expect(find.text('OKX Futures · 4 lots'), findsOneWidget);

      expect(find.text(r'$107,320'), findsOneWidget);
      expect(find.text(r'$66,375'), findsOneWidget);
      expect(find.text(r'$26,880'), findsOneWidget);
      expect(find.text(r'$31,200'), findsOneWidget);

      expect(find.text(r'+$4,210'), findsOneWidget);
      expect(find.text(r'-$820'), findsOneWidget);
      expect(find.text(r'+$312'), findsOneWidget);
      expect(find.text(r'+$680'), findsOneWidget);
    });

    testWidgets('navigates to orders when Orders link tapped', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Orders →'));
      await tester.tap(find.text('Orders →'));
      await tester.pumpAndSettle();

      expect(find.text('Orders'), findsOneWidget);
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('navigates to exchange detail when exchange card tapped', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Binance').first);
      await tester.pumpAndSettle();

      expect(find.text('Exchange binance'), findsOneWidget);
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('navigates to trading terminal when position tile tapped', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('BTCUSDT'));
      await tester.tap(find.text('BTCUSDT'));
      await tester.pumpAndSettle();

      expect(find.text('Trading BTCUSDT'), findsOneWidget);
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('renders without overflow in landscape orientation', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(844, 390));
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byType(PortfolioScreen), findsOneWidget);
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('renders without overflow at 2x text scale', (tester) async {
      tester.binding.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(
        () => tester.binding.platformDispatcher.textScaleFactorTestValue = 1.0,
      );

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byType(PortfolioScreen), findsOneWidget);
    });
  });
}
