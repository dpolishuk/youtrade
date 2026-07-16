import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/presentation/theme/app_theme.dart';
import 'package:youtrade/presentation/theme/theme_extensions.dart';
import 'package:youtrade/presentation/theme/theme_mode.dart';
import 'package:youtrade/ui/screens/compare_screen.dart';
import 'package:youtrade/ui/widgets/compare/compare_chart.dart';
import 'package:youtrade/ui/widgets/compare/compare_models.dart';
import 'package:youtrade/ui/widgets/compare/compare_stats_table.dart';
import 'package:youtrade/ui/widgets/compare/symbol_selector.dart';

void main() {
  group('CompareScreen', () {
    final appColors = AppTheme.dark(
      AppVisualDirection.flux,
    ).extension<AppColorTheme>()!;

    Widget buildScreen() {
      return MaterialApp(
        theme: AppTheme.dark(AppVisualDirection.flux),
        home: const CompareScreen(),
      );
    }

    testWidgets('renders without overflow and shows chart and selectors', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Compare'), findsOneWidget);
      expect(find.text('3/4 · normalized %'), findsOneWidget);
      expect(find.byType(CompareChart), findsOneWidget);
      expect(find.byType(SymbolSelector), findsOneWidget);
      expect(find.byType(CompareStatsTable), findsOneWidget);
      expect(find.text('BTC'), findsWidgets);
      expect(find.text('ETH'), findsWidgets);
      expect(find.text('SOL'), findsWidgets);

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('does not show time range selector or stat cards', (
      tester,
    ) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('1D'), findsNothing);
      expect(find.text('1W'), findsNothing);
      expect(find.text('1M'), findsNothing);
      expect(find.text('3M'), findsNothing);
      expect(find.text('1Y'), findsNothing);
      expect(find.text('Correlation'), findsNothing);
      expect(find.text('Ratio'), findsNothing);
    });

    testWidgets('uses 30-period stats eyebrow', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('30-period stats'), findsOneWidget);
    });

    testWidgets('stats header has 8px top spacing', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final spacing = tester.widget<SizedBox>(
        find.byKey(const Key('statsHeaderSpacing')),
      );
      expect(spacing.height, 8);
    });

    testWidgets('count indicator updates when a symbol is toggled', (
      tester,
    ) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('3/4 · normalized %'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('symbol_chip_SOL')));
      await tester.pumpAndSettle();

      expect(find.text('2/4 · normalized %'), findsOneWidget);
    });

    testWidgets('uses mockup title and count typography', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final title = tester.widget<Text>(find.text('Compare'));
      expect(title.style?.fontFamily, 'Space Grotesk');
      expect(title.style?.fontSize, 18);
      expect(title.style?.fontWeight, FontWeight.w600);
      expect(title.style?.letterSpacing, closeTo(-0.02 * 18, 0.01));
      expect(title.style?.color, appColors.foreground);

      final count = tester.widget<Text>(find.text('3/4 · normalized %'));
      expect(count.style?.fontFamily, 'JetBrains Mono');
      expect(count.style?.fontSize, 9);
    });

    testWidgets('selecting a fifth symbol evicts the oldest selection', (
      tester,
    ) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('symbol_chip_AAPL')));
      await tester.pumpAndSettle();

      // Now BTC, ETH, SOL, AAPL are selected.
      expect(find.text('4/4 · normalized %'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('symbol_chip_GOLD')));
      await tester.pumpAndSettle();

      // BTC is evicted, GOLD added.
      expect(find.text('4/4 · normalized %'), findsOneWidget);
      final btcChip = tester.widget<Material>(
        find.byKey(const ValueKey('symbol_chip_BTC')),
      );
      expect(btcChip.color, isNot(compareSymbols[0].color));
      expect(find.text('GOLD'), findsWidgets);
    });

    testWidgets('cannot deselect the last symbol', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('symbol_chip_BTC')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('symbol_chip_ETH')));
      await tester.pumpAndSettle();

      // Only SOL remains selected; trying to remove it does nothing.
      expect(find.text('1/4 · normalized %'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('symbol_chip_SOL')));
      await tester.pumpAndSettle();

      expect(find.text('1/4 · normalized %'), findsOneWidget);
      final solChip = tester.widget<Material>(
        find.byKey(const ValueKey('symbol_chip_SOL')),
      );
      expect(solChip.color, compareSymbols[2].color);
    });

    testWidgets('renders line chart inside a card-colored container', (
      tester,
    ) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byType(CompareChart), findsOneWidget);
      expect(find.byType(LineChart), findsOneWidget);

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(CompareChart),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration! as BoxDecoration;
      final theme = Theme.of(tester.element(find.byType(CompareChart)));
      expect(decoration.color, theme.cardColor);
      expect(decoration.border, isA<Border>());
      expect(decoration.boxShadow, isNotNull);
    });
  });
}
