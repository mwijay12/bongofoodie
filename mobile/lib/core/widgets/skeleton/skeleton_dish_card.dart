import 'package:flutter/material.dart';
import '../../theme/app_tokens.dart';
import '../../theme/skeleton_colors.dart';
import 'skeleton_box.dart';

/// Skeleton placeholder for a dish card. Mirrors DishCardMetrics so it
/// keeps the same footprint as the real dish card while loading.
class SkeletonDishCard extends StatelessWidget {
  const SkeletonDishCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = SkeletonColors.of(context);
    return Container(
      width: DishCardMetrics.cardMaxWidth,
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: colors.base,
        borderRadius: BorderRadius.circular(AppRadius.v22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: SkeletonBox(
              width: DishCardMetrics.imageSize,
              height: DishCardMetrics.imageSize,
              radius: AppRadius.v18,
            ),
          ),
          const SizedBox(height: AppSpace.v10),
          const SkeletonBox(
            width: AppSpace.v40,
            height: AppSpace.md,
            radius: AppRadius.sm,
          ),
          const SizedBox(height: AppSpace.v4),
          const SkeletonLines(count: 1),
          const Spacer(),
          const SkeletonBox(
            width: AppSpace.v40,
            height: AppSpace.lg,
            radius: AppRadius.sm,
          ),
        ],
      ),
    );
  }
}
