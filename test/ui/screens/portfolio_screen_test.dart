import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/presentation/theme/theme_provider.dart';
import 'package:youtrade/ui/screens/portfolio_screen.dart';
import 'package:youtrade/ui/widgets/portfolio/allocation_bar.dart';
import 'package:youtrade/ui/widgets/portfolio/exchange_card.dart';
import 'package:youtrade/ui/widgets/portfolio/position_tile.dart';

void main() {
  group('PortfolioScreen', () {
    Widget buildScreen() {
      return ProviderScope(
        child: Consumer(
          builder: (context, ref, child) {
            final theme = ref.watch(appThemeProvider);
            return MaterialApp(theme: theme, home: const PortfolioScreen());
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

      expect(find.text('Aggregated net worth · 3 venues'), findsOneWidget);
      expect(find.textContaining(r'$124,350.42'), findsOneWidget);
      expect(find.text(r'+$1,284.50'), findsOneWidget);
      expect(find.text('+1.04%'), findsOneWidget);
      expect(find.text('24h'), findsOneWidget);

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('shows allocation bar and exchange cards', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byType(AllocationBar), findsOneWidget);
      expect(find.byType(ExchangeCard), findsNWidgets(3));

      expect(find.text('Allocation by venue'), findsOneWidget);
      expect(find.text('Mixed assets'), findsOneWidget);

      expect(find.text('Binance'), findsOneWidget);
      expect(find.text('Bybit'), findsOneWidget);
      expect(find.text('Coinbase'), findsOneWidget);

      expect(find.text('SPOT · PERPS · OPTIONS'), findsOneWidget);
      expect(find.text('PERPS · SPOT'), findsOneWidget);
      expect(find.text('SPOT'), findsOneWidget);

      expect(find.text(r'$55,957.69'), findsOneWidget);
      expect(find.text(r'$37,305.13'), findsOneWidget);
      expect(find.text(r'$31,087.60'), findsOneWidget);

      expect(find.text('+1.24%'), findsOneWidget);
      expect(find.text('-0.38%'), findsOneWidget);
      expect(find.text('+0.72%'), findsOneWidget);
    });

    testWidgets('shows open positions list with exact position details', (
      tester,
    ) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Open positions'), findsOneWidget);
      expect(find.text('Orders →'), findsOneWidget);
      expect(find.byType(PositionTile), findsNWidgets(3));

      expect(find.text('BTC'), findsOneWidget);
      expect(find.text('ETH'), findsOneWidget);
      expect(find.text('SOL'), findsOneWidget);

      expect(find.text('LONG'), findsNWidgets(2));
      expect(find.text('SHORT'), findsOneWidget);

      expect(find.text('Binance · 0.42 BTC'), findsOneWidget);
      expect(find.text('Bybit · 4.20 ETH'), findsOneWidget);
      expect(find.text('Binance · 120 SOL'), findsOneWidget);

      expect(find.text(r'$28,420.00'), findsOneWidget);
      expect(find.text(r'$12,610.00'), findsOneWidget);
      expect(find.text(r'$14,760.00'), findsOneWidget);

      expect(find.text(r'+$840.50'), findsOneWidget);
      expect(find.text(r'-$210.30'), findsOneWidget);
      expect(find.text(r'+$305.20'), findsOneWidget);
    });

    testWidgets('toggles visual direction when direction button tapped', (
      tester,
    ) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('FLUX'), findsOneWidget);
      expect(find.text('Flux Terminal'), findsOneWidget);
      expect(find.text('CARBON'), findsNothing);

      await tester.tap(find.text('FLUX'));
      await tester.pumpAndSettle();

      expect(find.text('CARBON'), findsOneWidget);
      expect(find.text('Carbon Terminal'), findsOneWidget);
      expect(find.text('FLUX'), findsNothing);
    });

    testWidgets('toggles theme mode when theme button tapped', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(PortfolioScreen));
      expect(Theme.of(context).brightness, Brightness.dark);

      await tester.tap(find.byIcon(Icons.dark_mode));
      await tester.pumpAndSettle();

      final contextAfter = tester.element(find.byType(PortfolioScreen));
      expect(Theme.of(contextAfter).brightness, Brightness.light);
    });
  });
}
