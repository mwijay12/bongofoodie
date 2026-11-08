import 'package:flutter/material.dart';
import 'app_colors.dart';

class SkeletonColors {
  const SkeletonColors(this.base, this.highlight);
  final Color base;
  final Color highlight;

  static SkeletonColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const SkeletonColors(AppColors.darkCard, AppColors.darkBorder)
          : const SkeletonColors(AppColors.surfaceWarm, AppColors.surface);
}
