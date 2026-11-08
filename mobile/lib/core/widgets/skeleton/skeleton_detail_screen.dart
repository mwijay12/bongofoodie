import 'package:flutter/material.dart';
import '../../theme/app_tokens.dart';
import 'skeleton_box.dart';
import 'skeleton_chip_row.dart';

/// Loading placeholder for the deep-linked dish route. Mirrors the hero,
/// title, chips, description and sticky-bar footprint of the real page.
class SkeletonDetailScreen extends StatelessWidget {
  const SkeletonDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkeletonBox(
          height: DishDetailMetrics.heroMaxHeight,
          radius: AppSpace.v0,
        ),
        const SizedBox(height: AppSpace.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.screenH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SkeletonBox(width: AppSpace.v220, height: AppSpace.v24),
              SizedBox(height: AppSpace.sm),
              SkeletonBox(width: AppSpace.v148, height: AppSpace.md),
              SizedBox(height: AppSpace.md),
              SkeletonBox(width: AppSpace.v148, height: AppSpace.v24),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.md),
        const SkeletonChipRow(),
        const SizedBox(height: AppSpace.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.screenH),
          child: const SkeletonLines(count: 3),
        ),
        const SizedBox(height: DishDetailMetrics.stickyBarHeight),
      ],
    );
  }
}
