import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:youtrade/domain/entities/symbol.dart';
import 'package:youtrade/domain/entities/ticker.dart';
import 'package:youtrade/domain/entities/venue.dart';
import 'package:youtrade/presentation/providers/selected_symbol_provider.dart';
import 'package:youtrade/presentation/theme/app_theme.dart';
import 'package:youtrade/presentation/theme/theme_extensions.dart';
import 'package:youtrade/presentation/theme/theme_mode.dart';
import 'package:youtrade/ui/widgets/trading_terminal/lower_tabs.dart';
import 'package:youtrade/ui/widgets/trading_terminal/symbol_chip_row.dart';
import 'package:youtrade/ui/widgets/trading_terminal/time_frame_selector.dart';
import 'package:youtrade/ui/widgets/trading_terminal/trade_ticket.dart';

final _symbol = TradingSymbol(
  base: 'BTC',
  quote: 'USDT',
  venue: Venue.binance,
  rawSymbol: 'BTCUSDT',
);

final _ticker = Ticker(
  symbol: _symbol,
  lastPrice: 100000,
  bid: 99900,
  ask: 100100,
  change24h: 1000,
  change24hPercent: 0.01,
  volume: 50000,
  timestamp: DateTime.utc(2026, 1, 1),
);

void main() {
  group('Trading terminal widgets use theme-derived colors', () {
    testWidgets('TimeFrameSelector compare button uses chip and borderSubtle', (
      tester,
    ) async {
      final theme = AppTheme.dark(AppVisualDirection.carbon);
      final appColors = theme.extension<AppColorTheme>()!;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            theme: theme,
            routerConfig: GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (_, _) => const Scaffold(body: TimeFrameSelector()),
                ),
                GoRoute(
                  path: '/markets/compare',
                  builder: (_, _) =>
                      const Scaffold(body: Center(child: Text('Compare'))),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final compareButton = find
          .descendant(
            of: find.byType(TimeFrameSelector),
            matching: find.widgetWithIcon(Material, Icons.stacked_line_chart),
          )
          .first;
      final material = tester.widget<Material>(compareButton);
      expect(material.color, appColors.chip);

      final container = tester.widget<Container>(
        find
            .descendant(of: compareButton, matching: find.byType(Container))
            .first,
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.border, isA<Border>());
      final border = decoration.border! as Border;
      expect(border.top.color, appColors.borderSubtle);
    });

    testWidgets('SymbolChipRow unselected chip uses chip and subtleText', (
      tester,
    ) async {
      final theme = AppTheme.dark(AppVisualDirection.carbon);
      final appColors = theme.extension<AppColorTheme>()!;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [selectedSymbolProvider.overrideWith((ref) => _symbol)],
          child: MaterialApp(
            theme: theme,
            home: const Scaffold(body: SymbolChipRow()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // XRP chip is unselected by default because the selected symbol is BTC.
      final xrpMaterial = tester.firstWidget<Material>(
        find.ancestor(of: find.text('XRP'), matching: find.byType(Material)),
      );
      expect(xrpMaterial.color, appColors.chip);

      final xrpText = tester.widget<Text>(find.text('XRP'));
      expect(xrpText.style?.color, appColors.subtleText);
    });

    testWidgets('LowerTabs uses borderSubtle and foreground/tertiaryText', (
      tester,
    ) async {
      final theme = AppTheme.dark(AppVisualDirection.carbon);
      final appColors = theme.extension<AppColorTheme>()!;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: theme,
            home: const Scaffold(body: LowerTabs()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final outerContainer = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(LowerTabs),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = outerContainer.decoration as BoxDecoration;
      final border = decoration.border! as Border;
      expect(border.bottom.color, appColors.borderSubtle);

      final selectedText = tester.widget<Text>(find.text('Trade'));
      expect(selectedText.style?.color, appColors.foreground);

      final unselectedText = tester.widget<Text>(find.text('Signals'));
      expect(unselectedText.style?.color, appColors.tertiaryText);
    });

    testWidgets(
      'TradeTicket price row uses chip, borderSubtle and foreground',
      (tester) async {
        final theme = AppTheme.dark(AppVisualDirection.carbon);
        final appColors = theme.extension<AppColorTheme>()!;

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: theme,
              home: Scaffold(
                body: TradeTicket(
                  symbol: _symbol,
                  tickerAsync: AsyncValue.data(_ticker),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final priceLabel = find.text('PRICE');
        final container = tester.widget<Container>(
          find.ancestor(of: priceLabel, matching: find.byType(Container)).first,
        );
        final decoration = container.decoration! as BoxDecoration;
        expect(decoration.color, appColors.chip);
        final border = decoration.border! as Border;
        expect(border.top.color, appColors.borderSubtle);

        final priceValue = tester.widget<Text>(find.text('100,000.0'));
        expect(priceValue.style?.color, appColors.foreground);
      },
    );
  });
}
