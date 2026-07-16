import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtrade/domain/entities/options_chain_strike.dart';
import 'package:youtrade/presentation/theme/app_theme.dart';
import 'package:youtrade/presentation/theme/theme_mode.dart';
import 'package:youtrade/ui/screens/options_chain_screen.dart';

void main() {
  group('OptionsChainScreen', () {
    Widget buildScreen({String? symbol, List<OptionChainStrike>? rows}) {
      return MaterialApp(
        theme: AppTheme.dark(AppVisualDirection.flux),
        home: OptionsChainScreen(symbol: symbol, rows: rows),
      );
    }

    testWidgets(
      'renders BTC header, spot price, expiry pills, headers and strike rows',
      (tester) async {
        await tester.pumpWidget(buildScreen(symbol: 'BTC'));
        await tester.pumpAndSettle();

        expect(find.text('BTC'), findsOneWidget);
        expect(find.text('OPTIONS'), findsOneWidget);
        expect(find.text('105,154'), findsOneWidget);
        expect(find.text('SPOT'), findsOneWidget);

        expect(find.text('26 JUN'), findsOneWidget);
        expect(find.text('25 JUL'), findsOneWidget);
        expect(find.text('29 AUG'), findsOneWidget);
        expect(find.text('26 SEP'), findsOneWidget);

        expect(find.text('CALLS'), findsOneWidget);
        expect(find.text('STRIKE'), findsOneWidget);
        expect(find.text('PUTS'), findsOneWidget);
        expect(find.text('IV'), findsNWidgets(2));
        expect(find.text('Δ'), findsNWidgets(2));
        expect(find.text('MARK'), findsNWidgets(2));

        expect(find.text('ATM strike 106,000 · highlighted'), findsOneWidget);

        for (final strike in ['98,000', '100,000', '102,000', '104,000']) {
          expect(find.text(strike), findsOneWidget);
        }
        expect(find.text('106,000'), findsOneWidget);
        for (final strike in ['108,000', '110,000', '112,000', '114,000']) {
          expect(find.text(strike), findsOneWidget);
        }

        expect(find.text('57%'), findsOneWidget);
        expect(find.text('0.77'), findsOneWidget);
        expect(find.text('0.0780'), findsOneWidget);
        expect(find.text('0.47'), findsOneWidget);
        expect(find.text('-0.53'), findsOneWidget);
        expect(find.text('0.0229'), findsOneWidget);
        expect(find.text('59%'), findsOneWidget);
        expect(find.text('67%'), findsNWidgets(3));
      },
    );

    testWidgets('switching expiry keeps all pills visible', (tester) async {
      await tester.pumpWidget(buildScreen(symbol: 'BTC'));
      await tester.pumpAndSettle();

      expect(find.text('26 JUN'), findsOneWidget);

      await tester.tap(find.text('25 JUL'));
      await tester.pumpAndSettle();

      expect(find.text('26 JUN'), findsOneWidget);
      expect(find.text('25 JUL'), findsOneWidget);
      expect(find.text('29 AUG'), findsOneWidget);
      expect(find.text('26 SEP'), findsOneWidget);
      expect(find.text('ATM strike 106,000 · highlighted'), findsOneWidget);
    });

    testWidgets('empty chain shows no strikes message', (tester) async {
      await tester.pumpWidget(buildScreen(symbol: 'BTC', rows: []));
      await tester.pumpAndSettle();

      expect(find.text('No strikes available'), findsOneWidget);
    });

    testWidgets('uses default BTC chain when no symbol is provided', (
      tester,
    ) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('BTC'), findsOneWidget);
      expect(find.text('ATM strike 106,000 · highlighted'), findsOneWidget);
    });

    testWidgets('normalizes BTCUSDT raw symbol to BTC', (tester) async {
      await tester.pumpWidget(buildScreen(symbol: 'BTCUSDT'));
      await tester.pumpAndSettle();

      expect(find.text('BTC'), findsOneWidget);
      expect(find.text('BTCUSDT'), findsNothing);
    });

    testWidgets('uses requested symbol for spot and strike data', (
      tester,
    ) async {
      await tester.pumpWidget(buildScreen(symbol: 'ETHUSDT'));
      await tester.pumpAndSettle();

      expect(find.text('ETH'), findsOneWidget);
      // ETH spot is different from BTC spot, so the ATM strike should differ.
      expect(find.text('ATM strike 106,000 · highlighted'), findsNothing);
    });

    testWidgets('normalizes lowercase symbol to uppercase display', (
      tester,
    ) async {
      await tester.pumpWidget(buildScreen(symbol: 'btcusdt'));
      await tester.pumpAndSettle();

      expect(find.text('BTC'), findsOneWidget);
    });

    testWidgets('displays arbitrary symbol after stripping futures suffix', (
      tester,
    ) async {
      await tester.pumpWidget(buildScreen(symbol: 'XYZ=F'));
      await tester.pumpAndSettle();

      expect(find.text('XYZ'), findsOneWidget);
    });
  });
}
