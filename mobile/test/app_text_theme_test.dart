import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bongo_foodie/core/theme/app_colors.dart';
import 'package:bongo_foodie/core/theme/app_text_theme.dart';
import 'package:bongo_foodie/core/theme/app_theme.dart';
import 'package:bongo_foodie/core/theme/app_type.dart';

List<TextStyle?> _styles(TextTheme theme) => [
      theme.displayLarge,
      theme.displayMedium,
      theme.displaySmall,
      theme.headlineLarge,
      theme.headlineMedium,
      theme.headlineSmall,
      theme.titleLarge,
      theme.titleMedium,
      theme.titleSmall,
      theme.bodyLarge,
      theme.bodyMedium,
      theme.bodySmall,
      theme.labelLarge,
      theme.labelMedium,
      theme.labelSmall,
    ];

void main() {
  test('light and dark themes share a readable type scale', () {
    final light = withAccessibleTypography(buildAppTheme(), dark: false);
    final dark = withAccessibleTypography(AppTheme.dark(), dark: true);

    for (final theme in [light, dark]) {
      for (final style in _styles(theme.textTheme)) {
        expect(style, isNotNull);
        expect(
          style!.fontSize,
          greaterThanOrEqualTo(AppType.minReadableFontSize),
        );
      }
    }
  });

  test('dark mode gets the same typography with dark-safe semantic colors', () {
    final light = withAccessibleTypography(buildAppTheme(), dark: false);
    final dark = withAccessibleTypography(AppTheme.dark(), dark: true);

    expect(light.textTheme.bodyLarge!.color, AppColors.ink);
    expect(light.textTheme.labelSmall!.color, AppColors.primaryDeep);
    expect(dark.textTheme.bodyLarge!.color, AppColors.surface);
    expect(dark.textTheme.bodyMedium!.color, AppColors.darkTextSecondary);
    expect(dark.textTheme.labelSmall!.color, AppColors.heroLight);
    expect(
      dark.textTheme.bodyLarge!.fontSize,
      light.textTheme.bodyLarge!.fontSize,
    );
  });
}
