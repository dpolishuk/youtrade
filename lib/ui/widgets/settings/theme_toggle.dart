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
    final appColors = Theme.of(context).extension<AppColorTheme>()!;
    final settings = ref.watch(themeSettingsProvider);
    final label = settings.themeMode == ThemeMode.light ? 'LIGHT' : 'DARK';

    return SettingsTile(
      title: 'Theme',
      trailing: SettingsToggleButton(
        label: label,
        textColor: appColors.foreground,
        onTap: () => ref.read(themeSettingsProvider.notifier).toggleLightDark(),
      ),
    );
  }
}

class VisualDirectionToggle extends ConsumerWidget {
  const VisualDirectionToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appColors = Theme.of(context).extension<AppColorTheme>()!;
    final settings = ref.watch(themeSettingsProvider);
    final label = settings.visualDirection == AppVisualDirection.flux
        ? 'FLUX'
        : 'CARBON';

    return SettingsTile(
      title: 'Visual direction',
      isLast: true,
      trailing: SettingsToggleButton(
        label: label,
        textColor: appColors.accent,
        onTap: () =>
            ref.read(themeSettingsProvider.notifier).toggleVisualDirection(),
      ),
    );
  }
}
