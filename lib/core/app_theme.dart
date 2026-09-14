import 'package:flutter/material.dart';

class AppTheme {
  static const Color _lightBackground = Color(0xFFF1F5F3);
  static const Color _darkBackground = Color(0xFF07111F);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF087A57),
      brightness: Brightness.light,
    ).copyWith(
      primary: const Color(0xFF087A57),
      onPrimary: Colors.white,
      secondary: const Color(0xFF996300),
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: const Color(0xFF10211B),
      onSurfaceVariant: const Color(0xFF40554D),
      outline: const Color(0xFFB7C8C1),
      error: const Color(0xFFB42318),
      onError: Colors.white,
    );

    return _build(
      brightness: Brightness.light,
      scheme: scheme,
      background: _lightBackground,
      fieldFill: Colors.white,
      navigationBackground: const Color(0xFFFFFFFF),
      navigationIndicator: const Color(0xFFD8F3E8),
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF35D399),
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFF55E0AC),
      onPrimary: const Color(0xFF003824),
      secondary: const Color(0xFFF6C453),
      onSecondary: const Color(0xFF3A2700),
      surface: const Color(0xFF0E1A2B),
      onSurface: const Color(0xFFF8FAFC),
      onSurfaceVariant: const Color(0xFFC2CFDD),
      outline: const Color(0xFF42546B),
      error: const Color(0xFFFF8A8A),
      onError: const Color(0xFF490006),
    );

    return _build(
      brightness: Brightness.dark,
      scheme: scheme,
      background: _darkBackground,
      fieldFill: const Color(0xFF111F32),
      navigationBackground: const Color(0xFF0A1626),
      navigationIndicator: const Color(0xFF173E35),
    );
  }

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme scheme,
    required Color background,
    required Color fieldFill,
    required Color navigationBackground,
    required Color navigationIndicator,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 19,
          fontWeight: FontWeight.w800,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outline.withValues(alpha: 0.55),
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fieldFill,
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        hintStyle: TextStyle(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.82),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 1.8),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: navigationBackground,
        indicatorColor: navigationIndicator,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
            size: selected ? 24 : 22,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 50),
          side: BorderSide(color: scheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: brightness == Brightness.dark
            ? const Color(0xFF18263A)
            : const Color(0xFF18332A),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
