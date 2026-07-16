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

      expect(appColors.accent, const Color(0xFF1634EF));
      expect(appColors.bullish, const Color(0xFF1D683F));
      expect(appColors.bearish, const Color(0xFFC0392B));
    });

    test('light theme uses a warm neutral background for both directions', () {
      final flux = AppTheme.light(AppVisualDirection.flux);
      final carbon = AppTheme.light(AppVisualDirection.carbon);

      expect(flux.colorScheme.surface, const Color(0xFFF1EFEE));
      expect(carbon.colorScheme.surface, const Color(0xFFF1EFEE));
      expect(flux.scaffoldBackgroundColor, const Color(0xFFF1EFEE));
      expect(carbon.scaffoldBackgroundColor, const Color(0xFFF1EFEE));
    });

    test('dark theme uses updated chip, border, and grid colors', () {
      final theme = AppTheme.dark(AppVisualDirection.carbon);
      final appColors = theme.extension<AppColorTheme>()!;

      expect(appColors.chip, const Color(0xFF10151F));
      expect(appColors.borderSubtle, const Color(0x12FFFFFF));
      expect(appColors.grid, const Color(0x0BFFFFFF));
    });

    test('light theme uses white chip and directional grid color', () {
      final flux = AppTheme.light(AppVisualDirection.flux);
      final carbon = AppTheme.light(AppVisualDirection.carbon);
      final fluxColors = flux.extension<AppColorTheme>()!;
      final carbonColors = carbon.extension<AppColorTheme>()!;

      expect(fluxColors.chip, const Color(0xFFFFFFFF));
      expect(carbonColors.chip, const Color(0xFFFFFFFF));
      expect(fluxColors.grid, const Color(0x0F020D23));
      expect(carbonColors.grid, const Color(0x0F020D23));
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
