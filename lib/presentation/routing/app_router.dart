import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../ui/auth/auth_gate_screen.dart';
import '../../ui/screens/compare_screen.dart';
import '../../ui/screens/exchange_detail_screen.dart';
import '../../ui/screens/markets_screen.dart';
import '../../ui/screens/options_chain_screen.dart';
import '../../ui/screens/orders_history_screen.dart';
import '../../ui/screens/portfolio_screen.dart';
import '../../ui/screens/settings_screen.dart';
import '../../ui/screens/trading_terminal_screen.dart';
import '../../ui/widgets/common/scaffold_with_nav_bar.dart';
import '../auth/auth_guard_provider.dart';
import '../auth/auth_state.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.read(authNotifierProvider.notifier);
  final refresh = _GoRouterRefreshStream(authNotifier.stream);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: refresh,
    errorBuilder: (context, state) => const _RedirectHome(),
    redirect: (context, state) {
      final location = state.uri.path;
      final fullLocation = state.uri.toString();
      final isAuthRoute = location == '/auth';
      final authState = ProviderScope.containerOf(
        context,
      ).read(authNotifierProvider);
      final isAuthenticated = authState is AuthAuthenticated;

      const publicRoutes = {'/markets', '/markets/compare'};
      final isPublicRoute = publicRoutes.contains(location) || isAuthRoute;

      if (!isAuthenticated && !isPublicRoute) {
        return Uri(
          path: '/auth',
          queryParameters: {'from': fullLocation},
        ).toString();
      }
      if (isAuthenticated && isAuthRoute) {
        final from = state.uri.queryParameters['from'];
        if (from != null &&
            from.isNotEmpty &&
            from.startsWith('/') &&
            !from.startsWith('//')) {
          return from;
        }
        return '/';
      }
      return null;
    },

    routes: [
      GoRoute(
        path: '/auth',
        builder: (context, state) =>
            const AuthGateScreen(child: SizedBox.shrink()),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const PortfolioScreen(),
                routes: [
                  GoRoute(
                    path: 'orders',
                    builder: (context, state) => const OrdersHistoryScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKey,
            routes: [
              GoRoute(
                path: '/markets',
                builder: (context, state) => const MarketsScreen(),
                routes: [
                  GoRoute(
                    path: 'exchange/:id',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return ExchangeDetailScreen(exchangeId: id);
                    },
                  ),
                  GoRoute(
                    path: 'compare',
                    builder: (context, state) => const CompareScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/trading',
                builder: (context, state) {
                  final symbol = state.uri.queryParameters['symbol'];
                  return TradingTerminalScreen(symbol: symbol);
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/markets/options',
                redirect: (context, state) => '/markets/options/BTC',
              ),
              GoRoute(
                path: '/markets/options/:symbol',
                builder: (context, state) {
                  final symbol = state.pathParameters['symbol']!;
                  return OptionsChainScreen(symbol: symbol);
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/account',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class _RedirectHome extends StatefulWidget {
  const _RedirectHome();

  @override
  State<_RedirectHome> createState() => _RedirectHomeState();
}

class _RedirectHomeState extends State<_RedirectHome> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.go('/');
      }
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
