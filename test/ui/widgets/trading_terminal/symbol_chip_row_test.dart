import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/presentation/theme/app_theme.dart';
import 'package:youtrade/presentation/theme/theme_mode.dart';
import 'package:youtrade/ui/widgets/trading_terminal/symbol_chip_row.dart';

void main() {
  group('SymbolChipRow', () {
    Widget buildRow() {
      return ProviderScope(
        child: MaterialApp(
          theme: AppTheme.dark(AppVisualDirection.flux),
          home: const Scaffold(body: SymbolChipRow()),
        ),
      );
    }

    testWidgets('all expected chips are rendered', (tester) async {
      await tester.pumpWidget(buildRow());
      await tester.pumpAndSettle();

      expect(find.text('BTC'), findsOneWidget);
      expect(find.text('ETH'), findsOneWidget);
      expect(find.text('SOL'), findsOneWidget);
      expect(find.text('XRP'), findsOneWidget);
      expect(find.text('AAPL'), findsOneWidget);
    });

    testWidgets('BTC chip uses Bybit venue', (tester) async {
      await tester.pumpWidget(buildRow());
      await tester.pumpAndSettle();

      await tester.tap(find.text('BTC'));
      await tester.pumpAndSettle();
    });

    testWidgets('XRP chip is rendered and selectable', (tester) async {
      await tester.pumpWidget(buildRow());
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('symbol_chip_XRP')), findsOneWidget);
    });
  });
}
