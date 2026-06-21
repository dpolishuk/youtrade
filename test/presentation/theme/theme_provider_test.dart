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

    test('rapid light/dark toggles end in the correct state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(themeSettingsProvider.notifier);

      for (var i = 0; i < 20; i++) {
        notifier.toggleLightDark();
      }

      expect(container.read(themeSettingsProvider).themeMode, ThemeMode.dark);

      notifier.toggleLightDark();
      expect(container.read(themeSettingsProvider).themeMode, ThemeMode.light);
    });

    test('concurrent notifier reads return consistent state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(themeSettingsProvider.notifier)
          .setThemeMode(ThemeMode.light);
      container
          .read(themeSettingsProvider.notifier)
          .setVisualDirection(AppVisualDirection.carbon);

      const expected = ThemeSettings(
        themeMode: ThemeMode.light,
        visualDirection: AppVisualDirection.carbon,
      );

      final reads = await Future.wait(
        List.generate(50, (_) async => container.read(themeSettingsProvider)),
      );

      expect(reads, everyElement(expected));
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

    testWidgets('resolves light theme when system brightness is light', (
      tester,
    ) async {
      tester.binding.platformDispatcher.platformBrightnessTestValue =
          Brightness.light;
      addTearDown(() {
        tester.binding.platformDispatcher.clearPlatformBrightnessTestValue();
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(themeSettingsProvider.notifier)
          .setThemeMode(ThemeMode.system);
      await tester.pump();

      final theme = container.read(appThemeProvider);
      expect(theme.brightness, Brightness.light);
      expect(
        theme.colorScheme.primary,
        AppTheme.light(AppVisualDirection.flux).colorScheme.primary,
      );
    });

    testWidgets('resolves dark theme when system brightness is dark', (
      tester,
    ) async {
      tester.binding.platformDispatcher.platformBrightnessTestValue =
          Brightness.dark;
      addTearDown(() {
        tester.binding.platformDispatcher.clearPlatformBrightnessTestValue();
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(themeSettingsProvider.notifier)
          .setThemeMode(ThemeMode.system);
      await tester.pump();

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
