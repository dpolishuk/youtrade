import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:youtrade/core/result.dart';
import 'package:youtrade/domain/auth/local_auth_service.dart';
import 'package:youtrade/domain/entities/candle.dart';
import 'package:youtrade/domain/entities/order_book.dart';
import 'package:youtrade/domain/entities/symbol.dart';
import 'package:youtrade/domain/entities/ticker.dart';
import 'package:youtrade/domain/entities/timeframe.dart';
import 'package:youtrade/domain/entities/trade.dart';
import 'package:youtrade/domain/repositories/market_data_repository.dart';
import 'package:youtrade/presentation/auth/auth_guard_provider.dart';
import 'package:youtrade/presentation/providers/repository_provider.dart';
import 'package:youtrade/presentation/routing/app_router.dart';
import 'package:youtrade/presentation/theme/app_theme.dart';
import 'package:youtrade/presentation/theme/theme_extensions.dart';
import 'package:youtrade/presentation/theme/theme_mode.dart';
import 'package:youtrade/presentation/theme/theme_provider.dart';
import 'package:youtrade/ui/widgets/common/scaffold_with_nav_bar.dart';

import '../../../fakes/fake_pin_auth_service.dart';

class _MockLocalAuthService extends Mock implements LocalAuthService {}

final class _FakeMarketDataRepository implements MarketDataRepository {
  @override
  Future<Result<Ticker>> getTicker(TradingSymbol symbol) async => Success(
    Ticker(
      symbol: symbol,
      lastPrice: 100000,
      bid: 99900,
      ask: 100100,
      change24h: 1000,
      change24hPercent: 0.01,
      volume: 1000,
      timestamp: DateTime.utc(2026, 1, 1),
    ),
  );

  @override
  Future<Result<List<Candle>>> getCandles(
    TradingSymbol symbol,
    Timeframe timeframe, {
    int? limit,
  }) async => const Success<List<Candle>>([]);

  @override
  Future<Result<OrderBook>> getOrderBook(
    TradingSymbol symbol, {
    int? depth,
  }) async => Success(
    OrderBook(
      bids: const [],
      asks: const [],
      timestamp: DateTime.utc(2026, 1, 1),
    ),
  );

  @override
  Future<Result<List<Trade>>> getTrades(
    TradingSymbol symbol, {
    int? limit,
  }) async => const Success<List<Trade>>([]);

  @override
  Stream<Result<Ticker>> watchTicker(TradingSymbol symbol) => Stream.value(
    Success(
      Ticker(
        symbol: symbol,
        lastPrice: 100000,
        bid: 99900,
        ask: 100100,
        change24h: 1000,
        change24hPercent: 0.01,
        volume: 1000,
        timestamp: DateTime.utc(2026, 1, 1),
      ),
    ),
  );

  @override
  Stream<Result<OrderBook>> watchOrderBook(TradingSymbol symbol) =>
      Stream.value(
        Success(
          OrderBook(
            bids: const [],
            asks: const [],
            timestamp: DateTime.utc(2026, 1, 1),
          ),
        ),
      );

  @override
  Stream<Result<List<Trade>>> watchTrades(TradingSymbol symbol) =>
      Stream.value(const Success<List<Trade>>([]));
}

void main() {
  late _MockLocalAuthService mockService;
  late FakePinAuthService fakePinAuth;

  setUp(() {
    mockService = _MockLocalAuthService();
    fakePinAuth = FakePinAuthService(initialPin: '1234');
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        localAuthServiceProvider.overrideWithValue(mockService),
        pinAuthServiceProvider.overrideWithValue(fakePinAuth),
        marketDataRepositoryProvider.overrideWithValue(
          _FakeMarketDataRepository(),
        ),
      ],
    );
  }

  Future<void> pumpFrames(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Widget buildRouter({
    required GoRouter router,
    required ProviderContainer container,
    ThemeData? theme,
    ThemeData? darkTheme,
    ThemeMode? themeMode,
  }) {
    return UncontrolledProviderScope(
      container: container,
      child: Consumer(
        builder: (context, ref, child) {
          final appTheme = ref.watch(appThemeProvider);
          return MaterialApp.router(
            theme: theme ?? appTheme,
            darkTheme: darkTheme ?? appTheme,
            themeMode: themeMode ?? ThemeMode.dark,
            routerConfig: router,
          );
        },
      ),
    );
  }

  group('ScaffoldWithNavBar', () {
    testWidgets('renders mockup tab labels in order', (tester) async {
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      final container = createContainer();
      final router = container.read(appRouterProvider);

      container.read(authNotifierProvider.notifier).authenticateWithPin('1234');
      router.go('/');

      await tester.pumpWidget(
        buildRouter(router: router, container: container),
      );
      await pumpFrames(tester);

      final labels = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byKey(const Key('bottom-nav')),
              matching: find.byType(Text),
            ),
          )
          .map((t) => t.data)
          .toList();

      expect(labels, ['Portfolio', 'Markets', 'Trade', 'Options', 'More']);
    });

    testWidgets('uses mockup background color', (tester) async {
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      final container = createContainer();
      final router = container.read(appRouterProvider);

      container.read(authNotifierProvider.notifier).authenticateWithPin('1234');
      router.go('/');

      await tester.pumpWidget(
        buildRouter(router: router, container: container),
      );
      await pumpFrames(tester);

      final navContainer = tester.widget<Container>(
        find.byKey(const Key('bottom-nav')),
      );
      final decoration = navContainer.decoration! as BoxDecoration;
      expect(decoration.color, const Color(0xFF080B12));
    });

    testWidgets('uses white background in light mode', (tester) async {
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      final container = createContainer();
      final router = container.read(appRouterProvider);

      container.read(authNotifierProvider.notifier).authenticateWithPin('1234');
      router.go('/');

      await tester.pumpWidget(
        buildRouter(
          router: router,
          container: container,
          theme: AppTheme.light(AppVisualDirection.carbon),
          darkTheme: AppTheme.dark(AppVisualDirection.carbon),
          themeMode: ThemeMode.light,
        ),
      );
      await pumpFrames(tester);

      final navContainer = tester.widget<Container>(
        find.byKey(const Key('bottom-nav')),
      );
      final decoration = navContainer.decoration! as BoxDecoration;
      expect(decoration.color, const Color(0xFFFFFFFF));
    });

    testWidgets('shows active dot only on selected tab', (tester) async {
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      final container = createContainer();
      final router = container.read(appRouterProvider);

      container.read(authNotifierProvider.notifier).authenticateWithPin('1234');
      router.go('/');

      await tester.pumpWidget(
        buildRouter(router: router, container: container),
      );
      await pumpFrames(tester);

      for (var i = 0; i < 5; i++) {
        final opacity = tester.widget<Opacity>(
          find.byKey(Key('bottom-nav-dot-$i')),
        );
        expect(opacity.opacity, i == 0 ? 1.0 : 0.0);
      }

      // Prevents regression where the active dot loses the accent glow shadow.
      final activeDotContainer = tester.widget<Container>(
        find.descendant(
          of: find.byKey(const Key('bottom-nav-dot-0')),
          matching: find.byType(Container),
        ),
      );
      final decoration = activeDotContainer.decoration! as BoxDecoration;
      final appColors = Theme.of(
        tester.element(find.byType(ScaffoldWithNavBar)),
      ).extension<AppColorTheme>()!;
      expect(decoration.boxShadow, isNotNull);
      expect(decoration.boxShadow, hasLength(1));
      expect(decoration.boxShadow!.single.color, appColors.accentGlow);
    });

    testWidgets('updates active dot when tab changes', (tester) async {
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      final container = createContainer();
      final router = container.read(appRouterProvider);

      container.read(authNotifierProvider.notifier).authenticateWithPin('1234');
      router.go('/');

      await tester.pumpWidget(
        buildRouter(router: router, container: container),
      );
      await pumpFrames(tester);

      await tester.tap(find.byKey(const Key('bottom-nav-item-2')));
      await pumpFrames(tester);

      for (var i = 0; i < 5; i++) {
        final opacity = tester.widget<Opacity>(
          find.byKey(Key('bottom-nav-dot-$i')),
        );
        expect(opacity.opacity, i == 2 ? 1.0 : 0.0);
      }

      container.dispose();
    });

    testWidgets('renders global app header on portfolio branch', (
      tester,
    ) async {
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      final container = createContainer();
      final router = container.read(appRouterProvider);

      container.read(authNotifierProvider.notifier).authenticateWithPin('1234');
      router.go('/');

      await tester.pumpWidget(
        buildRouter(router: router, container: container),
      );
      await pumpFrames(tester);

      expect(find.text('YouTrade'), findsOneWidget);
      expect(find.text('FLUX TERMINAL'), findsOneWidget);
      expect(find.byIcon(Icons.dark_mode), findsOneWidget);
      expect(find.text('FLUX'), findsOneWidget);
    });

    testWidgets('global header persists when switching to markets branch', (
      tester,
    ) async {
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      final container = createContainer();
      final router = container.read(appRouterProvider);

      container.read(authNotifierProvider.notifier).authenticateWithPin('1234');
      router.go('/');

      await tester.pumpWidget(
        buildRouter(router: router, container: container),
      );
      await pumpFrames(tester);

      await tester.tap(find.byKey(const Key('bottom-nav-item-1')));
      await pumpFrames(tester);

      expect(find.text('YouTrade'), findsOneWidget);
      expect(find.text('Markets'), findsWidgets);
    });

    testWidgets('toggles visual direction from the global header', (
      tester,
    ) async {
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      final container = createContainer();
      final router = container.read(appRouterProvider);

      container.read(authNotifierProvider.notifier).authenticateWithPin('1234');
      router.go('/');

      await tester.pumpWidget(
        buildRouter(router: router, container: container),
      );
      await pumpFrames(tester);

      expect(find.text('FLUX'), findsOneWidget);
      expect(find.text('FLUX TERMINAL'), findsOneWidget);
      expect(find.text('CARBON'), findsNothing);

      await tester.tap(find.text('FLUX'));
      await tester.pumpAndSettle();

      expect(find.text('CARBON'), findsOneWidget);
      expect(find.text('CARBON TERMINAL'), findsOneWidget);
      expect(find.text('FLUX'), findsNothing);
    });

    testWidgets('toggles theme mode from the global header', (tester) async {
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      final container = createContainer();
      final router = container.read(appRouterProvider);

      container.read(authNotifierProvider.notifier).authenticateWithPin('1234');
      router.go('/');

      await tester.pumpWidget(
        buildRouter(router: router, container: container),
      );
      await pumpFrames(tester);

      final context = tester.element(find.byType(ScaffoldWithNavBar));
      expect(Theme.of(context).brightness, Brightness.dark);

      await tester.tap(find.byIcon(Icons.dark_mode));
      await tester.pumpAndSettle();

      final contextAfter = tester.element(find.byType(ScaffoldWithNavBar));
      expect(Theme.of(contextAfter).brightness, Brightness.light);
    });
  });
}
