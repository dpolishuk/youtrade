import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/theme/theme_provider.dart';
import 'ui/auth/auth_gate_screen.dart';

void main() {
  runApp(const ProviderScope(child: YouTradeApp()));
}

class YouTradeApp extends ConsumerWidget {
  const YouTradeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(appThemeProvider);

    return MaterialApp(
      title: 'YouTrade',
      theme: theme,
      darkTheme: theme,
      themeMode: ThemeMode.dark,
      home: AuthGateScreen(
        child: Scaffold(
          appBar: AppBar(title: const Text('YouTrade')),
          body: const Center(child: Text('Welcome to YouTrade')),
        ),
      ),
    );
  }
}
