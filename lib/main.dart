import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/routing/app_router.dart';
import 'presentation/theme/theme_provider.dart';

void main({List<Override> overrides = const []}) {
  runApp(ProviderScope(overrides: overrides, child: const YouTradeApp()));
}

class YouTradeApp extends ConsumerWidget {
  const YouTradeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(appThemeProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'YouTrade',
      theme: theme,
      darkTheme: theme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
