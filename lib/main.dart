import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/routing/app_router.dart';
import 'presentation/theme/theme_provider.dart';

void main({List<Override> overrides = const []}) async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env.example');
  } on Exception catch (_) {
    // .env.example missing — public endpoints still work without credentials.
  }
  runApp(ProviderScope(overrides: overrides, child: const YouTradeApp()));
}

class YouTradeApp extends ConsumerWidget {
  const YouTradeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(appThemeProvider);
    final settings = ref.watch(themeSettingsProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'YouTrade',
      theme: theme,
      darkTheme: theme,
      themeMode: settings.themeMode,
      routerConfig: router,
    );
  }
}
