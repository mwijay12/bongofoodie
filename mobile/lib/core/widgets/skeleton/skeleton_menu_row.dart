import 'package:flutter/material.dart';
import '../../theme/app_tokens.dart';
import '../../theme/skeleton_colors.dart';
import 'skeleton_box.dart';

/// Skeleton placeholder for a menu list row. Mirrors _MenuListTile layout
/// so the skeleton keeps the same footprint as the real row while loading.
class SkeletonMenuRow extends StatelessWidget {
  const SkeletonMenuRow({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = SkeletonColors.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: colors.base,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          const SkeletonBox(
            width: 84,
            height: 84,
            radius: AppRadius.v16,
          ),
          const SizedBox(width: AppSpace.v14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(height: AppSpace.md),
                SizedBox(height: AppSpace.v4),
                SkeletonLines(count: 2),
                SizedBox(height: AppSpace.v8),
                Row(
                  children: [
                    SkeletonBox(width: AppSpace.v40, height: AppSpace.sm),
                    SizedBox(width: AppSpace.v10),
                    SkeletonBox(width: AppSpace.v30, height: AppSpace.sm),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.v14),
          const SkeletonBox(
            width: AppSpace.huge,
            height: AppSpace.huge,
            circle: true,
          ),
        ],
      ),
    );
  }
}
