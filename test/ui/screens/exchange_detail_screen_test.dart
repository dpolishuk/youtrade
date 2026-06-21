import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/presentation/theme/app_theme.dart';
import 'package:youtrade/presentation/theme/theme_mode.dart';
import 'package:youtrade/ui/screens/exchange_detail_screen.dart';

void main() {
  Widget buildScreen() {
    return MaterialApp(
      theme: AppTheme.dark(AppVisualDirection.flux),
      home: const ExchangeDetailScreen(),
    );
  }

  group('ExchangeDetailScreen', () {
    testWidgets('renders without overflow and shows key content', (
      tester,
    ) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      expect(find.text('Binance'), findsWidgets);
      expect(find.text('API LIVE'), findsOneWidget);
      expect(find.text('Read-only keys active'), findsOneWidget);
      expect(find.text('Balance'), findsOneWidget);
      expect(find.text(r'$312,480.00'), findsOneWidget);
      expect(find.text('24h P&L'), findsOneWidget);
      expect(find.text('+\$6,620.00'), findsOneWidget);
      expect(find.text('BTC'), findsOneWidget);
      expect(find.text('ETH'), findsOneWidget);
      expect(find.text('USDT'), findsOneWidget);
      expect(find.text('SOL'), findsOneWidget);
      expect(find.text('Recent Trades'), findsOneWidget);
      expect(find.text('BTCUSDT'), findsOneWidget);
    });

    testWidgets('shows allocation percentage', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('45.2%'), findsOneWidget);
    });

    testWidgets('shows venue kinds label', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Spot · Perp · Options'), findsOneWidget);
    });
  });
}
