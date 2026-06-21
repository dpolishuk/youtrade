import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_theme.dart';
import 'theme_mode.dart';

/// Riverpod provider for the resolved [ThemeData].
///
/// Listens to [themeSettingsProvider] and resolves [ThemeMode.system] against
/// the current platform brightness.
final appThemeProvider = Provider<ThemeData>((ref) {
  final settings = ref.watch(themeSettingsProvider);
  final brightness = _resolveBrightness(settings.themeMode);

  return brightness == Brightness.light
      ? AppTheme.light(settings.visualDirection)
      : AppTheme.dark(settings.visualDirection);
});

/// Riverpod StateNotifier provider that owns theme mode and visual direction.
final themeSettingsProvider =
    StateNotifierProvider<ThemeNotifier, ThemeSettings>(
      (ref) => ThemeNotifier(),
    );

Brightness _resolveBrightness(ThemeMode mode) {
  if (mode == ThemeMode.light) return Brightness.light;
  if (mode == ThemeMode.dark) return Brightness.dark;
  return WidgetsBinding.instance.platformDispatcher.platformBrightness;
}

/// Immutable state held by [ThemeNotifier].
@immutable
class ThemeSettings {
  const ThemeSettings({
    this.themeMode = ThemeMode.dark,
    this.visualDirection = AppVisualDirection.flux,
  });

  final ThemeMode themeMode;
  final AppVisualDirection visualDirection;

  ThemeSettings copyWith({
    ThemeMode? themeMode,
    AppVisualDirection? visualDirection,
  }) {
    return ThemeSettings(
      themeMode: themeMode ?? this.themeMode,
      visualDirection: visualDirection ?? this.visualDirection,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ThemeSettings &&
        other.themeMode == themeMode &&
        other.visualDirection == visualDirection;
  }

  @override
  int get hashCode => Object.hash(themeMode, visualDirection);
}

/// Controls the app's theme mode and visual direction.
class ThemeNotifier extends StateNotifier<ThemeSettings> {
  ThemeNotifier() : super(const ThemeSettings());

  /// Sets the brightness mode (system / light / dark).
  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
  }

  /// Toggles between light and dark, leaving [ThemeMode.system] untouched.
  void toggleLightDark() {
    final next = state.themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    state = state.copyWith(themeMode: next);
  }

  /// Sets the visual direction (Flux / Carbon).
  void setVisualDirection(AppVisualDirection direction) {
    state = state.copyWith(visualDirection: direction);
  }

  /// Toggles between Flux and Carbon.
  void toggleVisualDirection() {
    final next = state.visualDirection == AppVisualDirection.flux
        ? AppVisualDirection.carbon
        : AppVisualDirection.flux;
    state = state.copyWith(visualDirection: next);
  }
}
