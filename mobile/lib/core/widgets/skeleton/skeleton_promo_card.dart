import 'package:flutter/material.dart';
import '../../theme/app_tokens.dart';
import '../../theme/skeleton_colors.dart';
import 'skeleton_box.dart';

/// Skeleton placeholder for a promo card. Mirrors PromoCardMetrics so it
/// keeps the same footprint as the real promo card while loading.
class SkeletonPromoCard extends StatelessWidget {
  const SkeletonPromoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = SkeletonColors.of(context);
    return Container(
      width: PromoCardMetrics.width,
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: colors.base,
        borderRadius: BorderRadius.circular(PromoCardMetrics.borderRadius),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SkeletonBox(
                  width: 80,
                  height: AppSpace.md,
                  radius: AppRadius.pill,
                ),
                const SizedBox(height: AppSpace.v8),
                const SkeletonBox(height: AppSpace.md),
                const SizedBox(height: AppSpace.v4),
                const SkeletonLines(count: 2),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.v10),
          const SkeletonBox(
            width: 76,
            height: 76,
            radius: AppRadius.v16,
          ),
        ],
      ),
    );
  }
}
