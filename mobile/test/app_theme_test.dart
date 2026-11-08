import 'package:bongo_foodie/core/theme/app_colors.dart';
import 'package:bongo_foodie/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('light theme uses the shared palette and Quicksand', () {
    final theme = buildAppTheme();
    expect(theme.scaffoldBackgroundColor, AppColors.cream);
    expect(theme.colorScheme.primary, AppColors.cta);
    expect(theme.colorScheme.onSurface, AppColors.ink);
    expect(theme.textTheme.bodyMedium?.color, AppColors.inkMuted);
    expect(theme.textTheme.bodyMedium?.fontFamily, 'Quicksand');
  });

  test('dark mode remains available', () {
    final theme = AppTheme.dark();
    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, AppColors.darkBackground);
  });
}
