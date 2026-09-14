import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ash_shifa_ruqyah/core/app_theme.dart';

void main() {
  test('light and dark themes keep primary content readable', () {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      final colors = theme.colorScheme;

      expect(
        _contrastRatio(colors.onSurface, colors.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrastRatio(colors.onSurface, theme.scaffoldBackgroundColor),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrastRatio(colors.onSurfaceVariant, colors.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(theme.navigationBarTheme.backgroundColor, isNotNull);
      expect(theme.navigationBarTheme.indicatorColor, isNotNull);
    }
  });

  test('themes expose the expected brightness modes', () {
    expect(AppTheme.light.brightness, Brightness.light);
    expect(AppTheme.dark.brightness, Brightness.dark);
  });
}

double _contrastRatio(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final lighter = firstLuminance > secondLuminance
      ? firstLuminance
      : secondLuminance;
  final darker = firstLuminance > secondLuminance
      ? secondLuminance
      : firstLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}
