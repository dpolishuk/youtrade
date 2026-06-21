import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../presentation/theme/theme_extensions.dart';
import '../../../presentation/theme/theme_mode.dart';
import '../../../presentation/theme/theme_provider.dart';
import 'settings_tile.dart';

class ThemeToggle extends ConsumerWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeSettingsProvider);
    final label = settings.themeMode == ThemeMode.light ? 'Light' : 'Dark';

    return SettingsTile(
      title: 'Theme',
      trailing: TextButton(
        onPressed: () =>
            ref.read(themeSettingsProvider.notifier).toggleLightDark(),
        child: Text(label),
      ),
    );
  }
}

class VisualDirectionToggle extends ConsumerWidget {
  const VisualDirectionToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>()!;
    final settings = ref.watch(themeSettingsProvider);
    final label = settings.visualDirection == AppVisualDirection.flux
        ? 'Flux'
        : 'Carbon';

    return SettingsTile(
      title: 'Visual direction',
      isLast: true,
      trailing: TextButton(
        onPressed: () =>
            ref.read(themeSettingsProvider.notifier).toggleVisualDirection(),
        child: Text(label, style: TextStyle(color: appColors.accent)),
      ),
    );
  }
}
