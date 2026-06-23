import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/domain/entities/symbol.dart';
import 'package:youtrade/domain/entities/venue.dart';
import 'package:youtrade/presentation/providers/selected_symbol_provider.dart';
import 'package:youtrade/presentation/theme/app_theme.dart';
import 'package:youtrade/presentation/theme/theme_extensions.dart';
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

    testWidgets('selects GOLD chip when GC=F is selected', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedSymbolProvider.overrideWith(
              (ref) => TradingSymbol(
                base: 'XAU',
                quote: 'USD',
                venue: Venue.okx,
                rawSymbol: 'GC=F',
              ),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.dark(AppVisualDirection.flux),
            home: const Scaffold(body: SymbolChipRow()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The GOLD chip should be selected even though its TradingSymbol base is
      // GOLD while the resolved metadata base is XAU.
      final goldChip = tester.widget<Material>(
        find.descendant(
          of: find.byKey(const ValueKey('symbol_chip_GOLD')),
          matching: find.byType(Material),
        ),
      );
      final appColors = AppTheme.dark(
        AppVisualDirection.flux,
      ).extension<AppColorTheme>()!;
      expect(goldChip.color, appColors.accent.withValues(alpha: 0.15));
    });

    testWidgets('all expected chips are rendered', (tester) async {
      await tester.pumpWidget(buildRow());
      await tester.pumpAndSettle();

      expect(find.text('BTC'), findsOneWidget);
      expect(find.text('ETH'), findsOneWidget);
      expect(find.text('SOL'), findsOneWidget);
      expect(find.text('AAPL'), findsOneWidget);
      expect(find.text('GOLD'), findsOneWidget);
    });
  });
}
