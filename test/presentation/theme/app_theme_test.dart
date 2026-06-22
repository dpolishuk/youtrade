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
      expect(theme.colorScheme.primary, const Color(0xFF0094A8));
    });

    test('dark theme uses expected brightness and color scheme', () {
      final theme = AppTheme.dark(AppVisualDirection.carbon);

      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.brightness, Brightness.dark);
      expect(theme.colorScheme.primary, const Color(0xFF3F73FF));
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
      // Assert canonical colors from lib/presentation/theme/app_theme.dart
      // so the test catches swaps or accidental overrides.
      expect(
        appColors!.bullish,
        const Color(0xFF2EE6A6),
        reason: 'bullish must be emerald vivid',
      );
      expect(
        appColors.bearish,
        const Color(0xFFFF5D77),
        reason: 'bearish must be rose',
      );
      expect(
        appColors.accent,
        const Color(0xFF00E6D2),
        reason: 'accent must be turquoise vivid for Flux dark',
      );
    });

    test('Carbon dark uses mockup surface and direction colors', () {
      final theme = AppTheme.dark(AppVisualDirection.carbon);
      final appColors = theme.extension<AppColorTheme>()!;

      expect(theme.colorScheme.surface, const Color(0xFF06080F));
      expect(appColors.bullish, const Color(0xFF16D196));
      expect(appColors.bearish, const Color(0xFFFF4D63));
    });

    test('Carbon light keeps direction-aware bullish/bearish colors', () {
      final theme = AppTheme.light(AppVisualDirection.carbon);
      final appColors = theme.extension<AppColorTheme>()!;

      expect(appColors.bullish, const Color(0xFF16D196));
      expect(appColors.bearish, const Color(0xFFFF4D63));
    });

    test('Flux and Carbon use different bullish/bearish colors', () {
      final flux = AppTheme.dark(AppVisualDirection.flux);
      final carbon = AppTheme.dark(AppVisualDirection.carbon);
      final fluxColors = flux.extension<AppColorTheme>()!;
      final carbonColors = carbon.extension<AppColorTheme>()!;

      expect(fluxColors.bullish, isNot(equals(carbonColors.bullish)));
      expect(fluxColors.bearish, isNot(equals(carbonColors.bearish)));
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
