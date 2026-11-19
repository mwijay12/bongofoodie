import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_type.dart';

TextStyle _style(
  TextStyle? source,
  double fontSize, {
  FontWeight fontWeight = FontWeight.w400,
  double height = 1.45,
  double letterSpacing = 0,
  Color? color,
}) {
  return (source ?? const TextStyle()).copyWith(
    fontSize: fontSize,
    fontWeight: fontWeight,
    height: height,
    letterSpacing: letterSpacing,
    color: color,
  );
}

TextTheme _accessibleTextTheme(ThemeData base, {required bool dark}) {
  final bodyColor = dark ? AppColors.surface : AppColors.ink;
  final mutedColor = dark ? AppColors.darkTextSecondary : AppColors.inkMuted;
  final accentColor = dark ? AppColors.heroLight : AppColors.primaryDeep;
  final t = base.textTheme.apply(
    bodyColor: bodyColor,
    displayColor: bodyColor,
  );

  return t.copyWith(
    displayLarge: _style(
      t.displayLarge,
      AppType.displayLarge,
      fontWeight: FontWeight.w700,
      height: 1.15,
      letterSpacing: -0.5,
      color: bodyColor,
    ),
    displayMedium: _style(
      t.displayMedium,
      AppType.displayMedium,
      fontWeight: FontWeight.w700,
      height: 1.15,
      letterSpacing: -0.5,
      color: bodyColor,
    ),
    displaySmall: _style(
      t.displaySmall,
      AppType.displaySmall,
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: -0.4,
      color: bodyColor,
    ),
    headlineLarge: _style(
      t.headlineLarge,
      AppType.headlineLarge,
      fontWeight: FontWeight.w700,
      height: 1.2,
      color: bodyColor,
    ),
    headlineMedium: _style(
      t.headlineMedium,
      AppType.headlineMedium,
      fontWeight: FontWeight.w700,
      height: 1.25,
      color: bodyColor,
    ),
    headlineSmall: _style(
      t.headlineSmall,
      AppType.headlineSmall,
      fontWeight: FontWeight.w700,
      height: 1.3,
      color: bodyColor,
    ),
    titleLarge: _style(
      t.titleLarge,
      AppType.titleLarge,
      fontWeight: FontWeight.w700,
      height: 1.35,
      color: bodyColor,
    ),
    titleMedium: _style(
      t.titleMedium,
      AppType.titleMedium,
      fontWeight: FontWeight.w600,
      height: 1.4,
      color: bodyColor,
    ),
    titleSmall: _style(
      t.titleSmall,
      AppType.titleSmall,
      fontWeight: FontWeight.w600,
      height: 1.4,
      color: bodyColor,
    ),
    bodyLarge: _style(
      t.bodyLarge,
      AppType.bodyLarge,
      height: 1.5,
      color: bodyColor,
    ),
    bodyMedium: _style(
      t.bodyMedium,
      AppType.bodyMedium,
      height: 1.5,
      color: mutedColor,
    ),
    bodySmall: _style(
      t.bodySmall,
      AppType.bodySmall,
      height: 1.5,
      color: mutedColor,
    ),
    labelLarge: _style(
      t.labelLarge,
      AppType.labelLarge,
      fontWeight: FontWeight.w700,
      height: 1.4,
      color: bodyColor,
    ),
    labelMedium: _style(
      t.labelMedium,
      AppType.labelMedium,
      fontWeight: FontWeight.w700,
      height: 1.4,
      color: bodyColor,
    ),
    labelSmall: _style(
      t.labelSmall,
      AppType.labelSmall,
      fontWeight: FontWeight.w700,
      height: 1.4,
      letterSpacing: 0.5,
      color: accentColor,
    ),
  );
}

/// Gives light and dark themes the same readable type scale. Wrapping the
/// existing themes keeps every other token and provider API unchanged.
ThemeData withAccessibleTypography(ThemeData base, {required bool dark}) {
  final textTheme = _accessibleTextTheme(base, dark: dark);
  final primaryTextTheme = textTheme.apply(
    bodyColor: base.colorScheme.onPrimary,
    displayColor: base.colorScheme.onPrimary,
  );
  return base.copyWith(
    textTheme: textTheme,
    primaryTextTheme: primaryTextTheme,
  );
}
