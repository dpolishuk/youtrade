import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/presentation/theme/app_theme.dart';
import 'package:youtrade/presentation/theme/theme_mode.dart';
import 'package:youtrade/presentation/theme/theme_provider.dart';

void main() {
  group('ThemeNotifier', () {
    test('starts with dark Flux theme by default', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final settings = container.read(themeSettingsProvider);

      expect(settings.themeMode, ThemeMode.dark);
      expect(settings.visualDirection, AppVisualDirection.flux);
    });

    test('setThemeMode updates the brightness mode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(themeSettingsProvider.notifier)
          .setThemeMode(ThemeMode.light);

      final settings = container.read(themeSettingsProvider);
      expect(settings.themeMode, ThemeMode.light);
      expect(settings.visualDirection, AppVisualDirection.flux);
    });

    test('toggleLightDark switches between light and dark', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(themeSettingsProvider.notifier);

      notifier.toggleLightDark();
      expect(container.read(themeSettingsProvider).themeMode, ThemeMode.light);

      notifier.toggleLightDark();
      expect(container.read(themeSettingsProvider).themeMode, ThemeMode.dark);
    });

    test('setVisualDirection updates the visual direction', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(themeSettingsProvider.notifier)
          .setVisualDirection(AppVisualDirection.carbon);

      final settings = container.read(themeSettingsProvider);
      expect(settings.visualDirection, AppVisualDirection.carbon);
      expect(settings.themeMode, ThemeMode.dark);
    });

    test('toggleVisualDirection switches between Flux and Carbon', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(themeSettingsProvider.notifier);

      notifier.toggleVisualDirection();
      expect(
        container.read(themeSettingsProvider).visualDirection,
        AppVisualDirection.carbon,
      );

      notifier.toggleVisualDirection();
      expect(
        container.read(themeSettingsProvider).visualDirection,
        AppVisualDirection.flux,
      );
    });
  });

  group('appThemeProvider', () {
    test('resolves dark Flux theme by default', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final theme = container.read(appThemeProvider);

      expect(theme.brightness, Brightness.dark);
      expect(
        theme.colorScheme.primary,
        AppTheme.dark(AppVisualDirection.flux).colorScheme.primary,
      );
    });

    test('resolves light theme when theme mode is light', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(themeSettingsProvider.notifier)
          .setThemeMode(ThemeMode.light);

      final theme = container.read(appThemeProvider);
      expect(theme.brightness, Brightness.light);
    });

    test('resolves carbon visual direction when selected', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(themeSettingsProvider.notifier)
          .setVisualDirection(AppVisualDirection.carbon);

      final theme = container.read(appThemeProvider);
      expect(
        theme.colorScheme.primary,
        AppTheme.dark(AppVisualDirection.carbon).colorScheme.primary,
      );
    });
  });
}
