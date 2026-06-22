# Mutation-style Regression Validation — youtrade-7k7.5

## Baseline

| Command | Result |
|---|---|
| `flutter test` | 601 tests passed (599 original + 2 new tests added to close gaps) |
| `flutter analyze` | No issues found |
| `dart format --set-exit-if-changed lib test integration_test tool` | 183 files formatted, 0 changed |

## Injected Regressions

For each area a deliberate bug was introduced, the relevant test(s) were run, at
least one test failed, and the bug was reverted before moving on.

| # | Area | Injected bug | Caught by | Result |
|---|---|---|---|---|
| 1 | Compare stats | Swapped positive-return color from `appColors.bullish` to `appColors.bearish` in `lib/ui/widgets/compare/compare_stats_table.dart:115-117`. | `test/ui/widgets/compare/compare_stats_table_test.dart` line 51: `return column shows exact positive return and bullish color`. | Caught |
| 2 | Recent trades | Changed `take(5)` to `take(3)` in `lib/ui/widgets/trading_terminal/recent_trades_strip.dart:26`. | `test/ui/widgets/trading_terminal/recent_trades_strip_test.dart` line 110: `limits to five trades and drops older rows`. | Caught |
| 3 | Candlestick chart | Forced non-empty candle state to render `CircularProgressIndicator` in `lib/ui/widgets/trading_terminal/candlestick_chart.dart:36`. | `test/ui/widgets/trading_terminal/candlestick_chart_test.dart` line 42: `expect(find.byType(CircularProgressIndicator), findsNothing)` (pumpAndSettle timeout). | Caught |
| 4 | Symbol normalization in `TradingTerminalScreen` | Removed `BTCUSDT` from the `BTC` switch case in `lib/ui/screens/trading_terminal_screen.dart:67`. | Initially **NOT caught** by existing tests. Added `test/ui/screens/trading_terminal_screen_test.dart` test `normalizes BTCUSDT symbol parameter to BTC` which records the resolved symbol via `_SymbolRecordingRepository` and asserts `base == 'BTC'`. Follow-up bead: `youtrade-7k7.8`. | Caught after test added |
| 5 | AppRouter external redirect | Removed the `!from.startsWith('//')` guard in `lib/presentation/routing/app_router.dart:52-55`. | `test/presentation/routing/app_router_test.dart` line 609: `rejects from query parameter starting with //`. | Caught |
| 6 | AuthNotifier lockout | Made `_lockoutRemainingSeconds` always return `0` in `lib/presentation/auth/auth_notifier.dart:154-159`. | `test/presentation/auth/auth_notifier_test.dart` lines 817, 976, 1043: `locks PIN entry after max failed attempts` and related lockout tests. | Caught |
| 7 | Offline/demo fallback store wiring | Hard-coded `venueSources` to always use online REST/WebSocket sources in `lib/presentation/providers/repository_provider.dart:149-180`. | Initially **NOT caught** by existing tests (integration test overrides repository with a fake; unit tests construct repository directly). Added `test/presentation/providers/repository_provider_test.dart` which asserts offline connectivity yields empty `venueSources` and a `DemoMarketDataStore` fallback. Exposed testability getters `fallbackStore` and `venueSources` on `MarketDataRepositoryImpl`. Follow-up bead: `youtrade-7k7.9`. | Caught after test added |

## Mutation Score

- Injected regressions: 7
- Caught by existing tests: 5
- Caught only after strengthening tests: 2
- **Final catch rate: 7 / 7 = 100%**

## Follow-up Beads

- `youtrade-7k7.8` — Add BTCUSDT normalization test for TradingTerminalScreen (closed).
- `youtrade-7k7.9` — Add offline fallback store wiring test for repository provider (closed).

## Final Verification

After all reverts and test additions:

```bash
flutter test          # 601 passed
flutter analyze       # No issues found
dart format --set-exit-if-changed lib test integration_test tool  # 0 changed
```

No injected regressions remain in the working tree.
