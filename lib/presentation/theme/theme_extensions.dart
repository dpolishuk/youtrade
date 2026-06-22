import 'package:flutter/material.dart';

/// App-specific color tokens that extend Flutter's [ThemeData].
///
/// These colors are semantic to trading and are not part of the standard
/// [ColorScheme], such as bullish/bearish indicators and glass surfaces.
@immutable
class AppColorTheme extends ThemeExtension<AppColorTheme> {
  const AppColorTheme({
    required this.bullish,
    required this.bearish,
    required this.accent,
    required this.foreground,
    required this.surfaceGlass,
    required this.subtleText,
    required this.borderSubtle,
    required this.tertiaryText,
    required this.chip,
    required this.line,
  });

  /// Positive price movement / long position.
  final Color bullish;

  /// Negative price movement / short position.
  final Color bearish;

  /// Directional accent hue (Flux = turquoise, Carbon = cobalt blue).
  final Color accent;

  /// Primary foreground text color (fg in the mockup tokens).
  final Color foreground;

  /// Translucent surface used for overlays and elevated panels.
  final Color surfaceGlass;

  /// Muted text color for secondary/metadata labels.
  final Color subtleText;

  /// Subtle divider/border color used across cards and inputs.
  final Color borderSubtle;

  /// Tertiary/muted text color (fg3 in the mockup tokens).
  final Color tertiaryText;

  /// Elevated chip / glyph background color.
  final Color chip;

  /// Card and row border color from the mockup `line` token.
  final Color line;

  @override
  AppColorTheme copyWith({
    Color? bullish,
    Color? bearish,
    Color? accent,
    Color? foreground,
    Color? surfaceGlass,
    Color? subtleText,
    Color? borderSubtle,
    Color? tertiaryText,
    Color? chip,
    Color? line,
  }) {
    return AppColorTheme(
      bullish: bullish ?? this.bullish,
      bearish: bearish ?? this.bearish,
      accent: accent ?? this.accent,
      foreground: foreground ?? this.foreground,
      surfaceGlass: surfaceGlass ?? this.surfaceGlass,
      subtleText: subtleText ?? this.subtleText,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      tertiaryText: tertiaryText ?? this.tertiaryText,
      chip: chip ?? this.chip,
      line: line ?? this.line,
    );
  }

  @override
  AppColorTheme lerp(ThemeExtension<AppColorTheme>? other, double t) {
    if (other is! AppColorTheme) return this;
    return AppColorTheme(
      bullish: Color.lerp(bullish, other.bullish, t)!,
      bearish: Color.lerp(bearish, other.bearish, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      foreground: Color.lerp(foreground, other.foreground, t)!,
      surfaceGlass: Color.lerp(surfaceGlass, other.surfaceGlass, t)!,
      subtleText: Color.lerp(subtleText, other.subtleText, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      tertiaryText: Color.lerp(tertiaryText, other.tertiaryText, t)!,
      chip: Color.lerp(chip, other.chip, t)!,
      line: Color.lerp(line, other.line, t)!,
    );
  }
}
