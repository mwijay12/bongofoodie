import 'package:flutter/material.dart';
import '../../theme/app_tokens.dart';
import '../../theme/skeleton_colors.dart';
import 'skeleton_box.dart';

/// Skeleton placeholder for the daily discovery card. Mirrors
/// DiscoveryCardMetrics so it keeps the same footprint as the real card.
class SkeletonDiscoveryCard extends StatelessWidget {
  const SkeletonDiscoveryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = SkeletonColors.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: colors.base,
        borderRadius: BorderRadius.circular(DiscoveryCardMetrics.borderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SkeletonBox(
                width: 20,
                height: 20,
                radius: AppRadius.pill,
                circle: true,
              ),
              const SizedBox(width: AppSpace.v8),
              Expanded(
                child: SkeletonBox(
                  height: AppSpace.md,
                  radius: AppRadius.sm,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.v4),
          const SkeletonBox(height: AppSpace.md),
          const SizedBox(height: AppSpace.v4),
          const SkeletonLines(count: 2),
        ],
      ),
    );
  }
}
