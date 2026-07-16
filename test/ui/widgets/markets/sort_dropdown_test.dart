import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/presentation/providers/market_screener_provider.dart';
import 'package:youtrade/presentation/theme/app_theme.dart';
import 'package:youtrade/presentation/theme/theme_mode.dart';
import 'package:youtrade/ui/widgets/markets/sort_dropdown.dart';

void main() {
  Widget buildApp(ProviderContainer container) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.dark(AppVisualDirection.carbon),
        home: const Scaffold(body: SortDropdown()),
      ),
    );
  }

  testWidgets('displays default sort label and descending arrow', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(buildApp(container));

    expect(find.text('Score'), findsOneWidget);
    // Descending arrow icon is shown.
    expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
  });

  testWidgets('tapping opens popup menu with all 8 options', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(buildApp(container));
    await tester.tap(find.byType(SortDropdown));
    await tester.pumpAndSettle();

    // The PopupMenu renders each option label; check a few distinct ones.
    expect(find.text('Volume'), findsWidgets);
    expect(find.text('Change %'), findsWidgets);
    expect(find.text('Open Interest'), findsWidgets);
    expect(find.text('Funding'), findsWidgets);
    expect(find.text('Volatility'), findsWidgets);
    expect(find.text('Spread'), findsWidgets);
    expect(find.text('Price'), findsWidgets);
  });

  testWidgets('selecting a new option sets it with descending=true', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(buildApp(container));
    await tester.tap(find.byType(SortDropdown));
    await tester.pumpAndSettle();

    // Tap "Volume" in the popup.
    await tester.tap(find.text('Volume').last);
    await tester.pumpAndSettle();

    final sort = container.read(marketScreenerSortProvider);
    expect(sort.option, SortOption.turnover);
    expect(sort.descending, isTrue);

    // The label now shows Volume.
    expect(find.text('Volume'), findsOneWidget);
  });

  testWidgets('re-selecting the active option flips descending', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Start with Score descending (default).
    await tester.pumpWidget(buildApp(container));

    // Open and re-tap Score.
    await tester.tap(find.byType(SortDropdown));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Score').last);
    await tester.pumpAndSettle();

    final sort = container.read(marketScreenerSortProvider);
    expect(sort.option, SortOption.score);
    expect(sort.descending, isFalse);

    // Ascending arrow now shown.
    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
  });
}
