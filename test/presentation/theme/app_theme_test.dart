import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/presentation/theme/app_theme.dart';
import 'package:youtrade/presentation/theme/theme_extensions.dart';
import 'package:youtrade/presentation/theme/theme_mode.dart';

void main() {
  group('AppTheme', () {
    test('light and dark themes are not equal', () {
      final light = AppTheme.light(AppVisualDirection.flux);
      final dark = AppTheme.dark(AppVisualDirection.flux);

      expect(light, isNot(equals(dark)));
      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);
    });

    test('light theme uses expected brightness and color scheme', () {
      final theme = AppTheme.light(AppVisualDirection.flux);

      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.brightness, Brightness.light);
      expect(theme.colorScheme.primary, const Color(0xFF005060));
    });

    test('dark theme uses expected brightness and color scheme', () {
      final theme = AppTheme.dark(AppVisualDirection.carbon);

      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.brightness, Brightness.dark);
      expect(theme.colorScheme.primary, const Color(0xFF0355F3));
    });

    test('Flux and Carbon directions produce different accent colors', () {
      final flux = AppTheme.dark(AppVisualDirection.flux);
      final carbon = AppTheme.dark(AppVisualDirection.carbon);

      expect(
        flux.colorScheme.primary,
        isNot(equals(carbon.colorScheme.primary)),
      );
    });

    test('theme includes AppColorTheme extension with trading colors', () {
      final theme = AppTheme.dark(AppVisualDirection.flux);
      final appColors = theme.extension<AppColorTheme>();

      expect(appColors, isNotNull);
      expect(appColors!.bullish, isA<Color>());
      expect(appColors.bearish, isA<Color>());
      expect(appColors.accent, equals(theme.colorScheme.primary));
    });

    test('display type uses Space Grotesk', () {
      final theme = AppTheme.dark(AppVisualDirection.flux);

      expect(theme.textTheme.displayLarge?.fontFamily, 'Space Grotesk');
      expect(theme.textTheme.headlineLarge?.fontFamily, 'Space Grotesk');
    });

    test('body and label type uses Geist', () {
      final theme = AppTheme.dark(AppVisualDirection.flux);

      expect(theme.textTheme.bodyMedium?.fontFamily, 'Geist');
      expect(theme.textTheme.labelLarge?.fontFamily, 'Geist');
      expect(theme.textTheme.headlineSmall?.fontFamily, 'Geist');
    });

    test('mono and serif helpers return expected families', () {
      const color = Colors.white;

      expect(AppTheme.mono(color: color).fontFamily, 'JetBrains Mono');
      expect(AppTheme.serifItalic(color: color).fontFamily, 'Instrument Serif');
    });
  });
}
