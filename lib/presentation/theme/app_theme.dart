import 'package:flutter/material.dart';

import 'theme_extensions.dart';
import 'theme_mode.dart';

/// Static factories for light and dark [ThemeData] instances.
///
/// Themes are dark-first and parameterized by [AppVisualDirection]
/// (Flux vs Carbon) so the two directions share the same structure but differ
/// in accent and background hues.
abstract final class AppTheme {
  static const _carbonSurface = Color(0xFF061336);
  static const _fluxSurface = Color(0xFF0A0F1E);
  static const _lightSurface = Color(0xFFFFFFFF);
  static const _titanium = Color(0xFFF7F4F3);

  static const _cobalt = Color(0xFF1634EF);
  static const _turquoise = Color(0xFF00BBCC);
  static const _turquoiseBold = Color(0xFF005060);
  static const _emerald = Color(0xFF01A54C);
  static const _emeraldBold = Color(0xFF1D683F);
  static const _rose = Color(0xFFFF4D4D);
  static const _roseBold = Color(0xFFDC2626);

  static const _carbon = Color(0xFF020D23);
  static const _white = Color(0xFFFFFFFF);
  static const _white55 = Color(0x8CFFFFFF);
  static const _white8 = Color(0x14FFFFFF);
  static const _white6 = Color(0x0FFFFFFF);
  static const _carbon60 = Color(0x99020D23);
  static const _carbon8 = Color(0x14020D23);

  /// Builds a dark theme for the given visual direction.
  static ThemeData dark(AppVisualDirection direction) {
    final primary = direction == AppVisualDirection.flux ? _turquoise : _cobalt;
    final surface = direction == AppVisualDirection.flux
        ? _fluxSurface
        : _carbonSurface;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      surface: surface,
      primary: primary,
      onPrimary: _white,
      secondary: const Color(0xFF1A1A1A),
      onSecondary: _white,
      error: _rose,
      onError: _white,
      outline: _white6,
      outlineVariant: _white8,
    );

    return _baseTheme(
      colorScheme: colorScheme,
      appColorTheme: AppColorTheme(
        bullish: _emerald,
        bearish: _rose,
        accent: primary,
        surfaceGlass: _white8,
        subtleText: _white55,
        borderSubtle: _white6,
      ),
    );
  }

  /// Builds a light theme for the given visual direction.
  static ThemeData light(AppVisualDirection direction) {
    final primary = direction == AppVisualDirection.flux
        ? _turquoiseBold
        : _cobalt;
    final accent = direction == AppVisualDirection.flux
        ? const Color(0xFFBDECF6)
        : _titanium;
    final surface = direction == AppVisualDirection.flux
        ? _titanium
        : _lightSurface;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      surface: surface,
      primary: primary,
      onPrimary: _white,
      secondary: _titanium,
      onSecondary: _carbon,
      error: _roseBold,
      onError: _white,
      outline: _carbon8,
      outlineVariant: _carbon8,
    );

    return _baseTheme(
      colorScheme: colorScheme,
      appColorTheme: AppColorTheme(
        bullish: _emeraldBold,
        bearish: _roseBold,
        accent: accent,
        surfaceGlass: _carbon8,
        subtleText: _carbon60,
        borderSubtle: _carbon8,
      ),
    );
  }

  static ThemeData _baseTheme({
    required ColorScheme colorScheme,
    required AppColorTheme appColorTheme,
  }) {
    final textTheme = _buildTextTheme(colorScheme.onSurface);

    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      canvasColor: colorScheme.surface,
      cardColor: colorScheme.surface,
      dividerColor: appColorTheme.borderSubtle,
      splashColor: appColorTheme.accent.withValues(alpha: 0.08),
      highlightColor: appColorTheme.accent.withValues(alpha: 0.04),
      extensions: [appColorTheme],
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: appColorTheme.borderSubtle),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: appColorTheme.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: appColorTheme.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: appColorTheme.surfaceGlass,
        selectedColor: colorScheme.primary,
        labelStyle: textTheme.labelMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: BorderSide.none,
      ),
    );
  }

  static TextTheme _buildTextTheme(Color onSurface) {
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Space Grotesk',
        fontSize: 80,
        height: 1.0,
        letterSpacing: -0.02 * 80,
        color: onSurface,
        fontWeight: FontWeight.w400,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Space Grotesk',
        fontSize: 48,
        height: 1.0,
        letterSpacing: -0.02 * 48,
        color: onSurface,
        fontWeight: FontWeight.w400,
      ),
      displaySmall: TextStyle(
        fontFamily: 'Space Grotesk',
        fontSize: 36,
        height: 1.05,
        letterSpacing: -0.02 * 36,
        color: onSurface,
        fontWeight: FontWeight.w400,
      ),
      headlineLarge: TextStyle(
        fontFamily: 'Geist',
        fontSize: 24,
        height: 1.1,
        letterSpacing: -0.01 * 24,
        color: onSurface,
        fontWeight: FontWeight.w500,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Geist',
        fontSize: 18,
        height: 1.2,
        letterSpacing: -0.005 * 18,
        color: onSurface,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Geist',
        fontSize: 18,
        height: 1.55,
        color: onSurface,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Geist',
        fontSize: 16,
        height: 1.55,
        color: onSurface,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Geist',
        fontSize: 14,
        height: 1.5,
        color: onSurface,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Geist',
        fontSize: 12,
        height: 1.2,
        letterSpacing: 0.05 * 12,
        color: onSurface,
        fontWeight: FontWeight.w500,
      ),
      labelMedium: TextStyle(
        fontFamily: 'Geist',
        fontSize: 11,
        height: 1.2,
        color: onSurface,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: TextStyle(
        fontFamily: 'Geist',
        fontSize: 9,
        height: 1.2,
        letterSpacing: 0.07 * 9,
        color: onSurface,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
