import 'package:flutter/material.dart';

import 'theme_extensions.dart';
import 'theme_mode.dart';

/// Static factories for light and dark [ThemeData] instances.
///
/// Themes are dark-first and parameterized by [AppVisualDirection]
/// (Flux vs Carbon) so the two directions share the same structure but differ
/// in accent and background hues. Colors are sourced from
/// [mockups/colors_and_type.css].
abstract final class AppTheme {
  // Surfaces
  static const _lightSurface = Color(0xFFFFFFFF); // --color-background
  static const _titanium = Color(0xFFF7F4F3); // --color-titanium

  // Brand accents (from the CSS triads)
  static const _carbonAccent = Color(0xFF3F73FF); // dark+carbon accent
  static const _carbonLightAccent = Color(0xFF1634EF); // light+carbon accent
  static const _turquoiseVivid = Color(0xFF00E6D2); // dark+flux accent
  static const _turquoiseBold = Color(0xFF0094A8); // light+flux accent
  static const _emeraldVivid = Color(0xFF2EE6A6); // dark+flux up
  static const _emeraldBold = Color(0xFF1D683F); // light+carbon up
  static const _emeraldLight = Color(0xFF00936B); // light+flux up
  static const _rose = Color(0xFFFF5D77); // dark+flux down
  static const _roseBold = Color(0xFFC0392B); // light+carbon down
  static const _roseLight = Color(0xFFD22A47); // light+flux down

  // Carbon direction tokens
  static const _carbonSurface = Color(0xFF06080F);
  static const _carbonUp = Color(0xFF16D196);
  static const _carbonDown = Color(0xFFFF4D63);

  // Neutrals
  static const _carbon = Color(0xFF020D23); // --color-carbon
  static const _white = Color(0xFFFFFFFF);
  static const _white55 = Color(0x8CFFFFFF); // ~ --color-white-50
  static const _white8 = Color(0x14FFFFFF); // --color-white-8
  static const _white7 = Color(0x12FFFFFF); // --color-border (dark)
  static const _carbon60 = Color(0x99020D23); // --color-carbon-60
  static const _carbon8 = Color(0x14020D23); // --color-carbon-8

  /// Builds a dark theme for the given visual direction.
  static ThemeData dark(AppVisualDirection direction) {
    final isCarbon = direction == AppVisualDirection.carbon;
    final primary = isCarbon ? _carbonAccent : _turquoiseVivid;
    final surface = _carbonSurface;
    final card = const Color(0xFF0E131F);
    final bullish = isCarbon ? _carbonUp : _emeraldVivid;
    final bearish = isCarbon ? _carbonDown : _rose;
    final accentGlow = isCarbon ? Colors.transparent : const Color(0x8000E6D2);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      surface: surface,
      primary: primary,
      onPrimary: _white,
      secondary: const Color(0xFF10151F),
      onSecondary: _white,
      error: bearish,
      onError: _white,
      outline: _white7,
      outlineVariant: _white8,
    );

    return _baseTheme(
      colorScheme: colorScheme,
      cardColor: card,
      appColorTheme: AppColorTheme(
        bullish: bullish,
        bearish: bearish,
        accent: primary,
        accentGlow: accentGlow,
        foreground: const Color(0xFFF2F5FA),
        surfaceGlass: _white8,
        subtleText: _white55,
        borderSubtle: _white7,
        tertiaryText: const Color(0x57FFFFFF),
        chip: const Color(0xFF10151F),
        line: const Color(0x12FFFFFF),
        grid: const Color(0x0BFFFFFF),
      ),
    );
  }

  /// Builds a light theme for the given visual direction.
  static ThemeData light(AppVisualDirection direction) {
    final isCarbon = direction == AppVisualDirection.carbon;
    final primary = isCarbon ? _carbonLightAccent : _turquoiseBold;
    final accent = isCarbon ? _carbonLightAccent : _turquoiseBold;
    const surface = Color(0xFFF1EFEE);
    const card = _lightSurface;
    final bullish = isCarbon ? _emeraldBold : _emeraldLight;
    final bearish = isCarbon ? _roseBold : _roseLight;
    final accentGlow = isCarbon ? Colors.transparent : const Color(0x590094A8);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      surface: surface,
      primary: primary,
      onPrimary: _white,
      secondary: _titanium,
      onSecondary: _carbon,
      error: bearish,
      onError: _white,
      outline: _carbon8,
      outlineVariant: _carbon8,
    );

    return _baseTheme(
      colorScheme: colorScheme,
      cardColor: card,
      appColorTheme: AppColorTheme(
        bullish: bullish,
        bearish: bearish,
        accent: accent,
        accentGlow: accentGlow,
        foreground: _carbon,
        surfaceGlass: _carbon8,
        subtleText: _carbon60,
        borderSubtle: _carbon8,
        tertiaryText: const Color(0x61020D23),
        chip: _white,
        line: const Color(0x17020D23),
        grid: const Color(0x0F020D23),
      ),
    );
  }

  static ThemeData _baseTheme({
    required ColorScheme colorScheme,
    required AppColorTheme appColorTheme,
    required Color cardColor,
  }) {
    final textTheme = _buildTextTheme(colorScheme.onSurface);

    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      canvasColor: colorScheme.surface,
      cardColor: cardColor,
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

  /// Returns a display type style using Space Grotesk.
  static TextStyle display({required Color color, double fontSize = 18}) =>
      TextStyle(
        fontFamily: 'Space Grotesk',
        fontSize: fontSize,
        color: color,
        fontWeight: FontWeight.w500,
      );

  /// Returns a monospace text style for prices, addresses and hashes.
  static TextStyle mono({required Color color, double fontSize = 14}) =>
      TextStyle(
        fontFamily: 'JetBrains Mono',
        fontSize: fontSize,
        color: color,
        fontWeight: FontWeight.w500,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// Returns an italic serif text style for editorial accents.
  static TextStyle serifItalic({required Color color, double fontSize = 16}) =>
      TextStyle(
        fontFamily: 'Instrument Serif',
        fontSize: fontSize,
        color: color,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w400,
      );

  static TextTheme _buildTextTheme(Color onSurface) {
    // Display and large headlines use Space Grotesk; body/UI use Geist,
    // matching the mockup type scale.
    const spaceGrotesk = TextStyle(fontFamily: 'Space Grotesk');
    const geist = TextStyle(fontFamily: 'Geist');

    return TextTheme(
      displayLarge: spaceGrotesk.copyWith(
        fontSize: 80,
        height: 1.0,
        letterSpacing: -0.02 * 80,
        color: onSurface,
        fontWeight: FontWeight.w400,
      ),
      displayMedium: spaceGrotesk.copyWith(
        fontSize: 48,
        height: 1.0,
        letterSpacing: -0.02 * 48,
        color: onSurface,
        fontWeight: FontWeight.w400,
      ),
      displaySmall: spaceGrotesk.copyWith(
        fontSize: 36,
        height: 1.05,
        letterSpacing: -0.02 * 36,
        color: onSurface,
        fontWeight: FontWeight.w400,
      ),
      headlineLarge: spaceGrotesk.copyWith(
        fontSize: 24,
        height: 1.1,
        letterSpacing: -0.01 * 24,
        color: onSurface,
        fontWeight: FontWeight.w500,
      ),
      headlineMedium: spaceGrotesk.copyWith(
        fontSize: 18,
        height: 1.2,
        letterSpacing: -0.005 * 18,
        color: onSurface,
        fontWeight: FontWeight.w500,
      ),
      headlineSmall: geist.copyWith(
        fontSize: 24,
        height: 1.1,
        letterSpacing: -0.01 * 24,
        color: onSurface,
        fontWeight: FontWeight.w500,
      ),
      titleLarge: geist.copyWith(
        fontSize: 18,
        height: 1.2,
        letterSpacing: -0.005 * 18,
        color: onSurface,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: geist.copyWith(
        fontSize: 18,
        height: 1.55,
        color: onSurface,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: geist.copyWith(
        fontSize: 16,
        height: 1.55,
        color: onSurface,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: geist.copyWith(
        fontSize: 14,
        height: 1.5,
        color: onSurface,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: geist.copyWith(
        fontSize: 12,
        height: 1.2,
        letterSpacing: 0.05 * 12,
        color: onSurface,
        fontWeight: FontWeight.w500,
      ),
      labelMedium: geist.copyWith(
        fontSize: 11,
        height: 1.2,
        color: onSurface,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: geist.copyWith(
        fontSize: 9,
        height: 1.2,
        letterSpacing: 0.07 * 9,
        color: onSurface,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
