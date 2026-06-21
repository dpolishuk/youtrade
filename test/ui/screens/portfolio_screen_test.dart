import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/ui/screens/portfolio_screen.dart';
import 'package:youtrade/ui/widgets/portfolio/allocation_bar.dart';
import 'package:youtrade/ui/widgets/portfolio/exchange_card.dart';
import 'package:youtrade/ui/widgets/portfolio/position_tile.dart';

void main() {
  group('PortfolioScreen', () {
    Widget buildScreen() {
      return ProviderScope(child: MaterialApp(home: const PortfolioScreen()));
    }

    testWidgets('renders total equity and 24h delta without overflow', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.textContaining(r'$124,350'), findsOneWidget);
      expect(find.text('+\$1,284.50'), findsOneWidget);
      expect(find.text('+1.04%'), findsOneWidget);
      expect(find.text('24h'), findsOneWidget);

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('shows allocation bar and exchange cards', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byType(AllocationBar), findsOneWidget);
      expect(find.byType(ExchangeCard), findsWidgets);
      expect(find.text('Binance'), findsOneWidget);
      expect(find.text('Bybit'), findsOneWidget);
      expect(find.text('Coinbase'), findsOneWidget);
    });

    testWidgets('shows open positions list with at least one tile', (
      tester,
    ) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Open positions'), findsOneWidget);
      expect(find.text('Orders →'), findsOneWidget);
      expect(find.byType(PositionTile), findsWidgets);
      expect(find.text('BTC'), findsOneWidget);
      expect(find.text('ETH'), findsOneWidget);
      expect(find.text('SOL'), findsOneWidget);
    });

    testWidgets('toggles visual direction when direction button tapped', (
      tester,
    ) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('FLUX'), findsOneWidget);

      await tester.tap(find.text('FLUX'));
      await tester.pumpAndSettle();

      expect(find.text('CARBON'), findsOneWidget);
    });

    testWidgets('toggles theme mode when theme button tapped', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.dark_mode));
      await tester.pumpAndSettle();

      expect(find.byType(PortfolioScreen), findsOneWidget);
    });
  });
}
