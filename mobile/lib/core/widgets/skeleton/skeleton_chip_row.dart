import 'package:flutter/material.dart';
import '../../theme/app_tokens.dart';
import '../../theme/skeleton_colors.dart';

/// Skeleton placeholder for category filter chips.
/// Renders 5 pills with varied widths at the real chip height (AppSpace.v42 / 42).
class SkeletonChipRow extends StatelessWidget {
  const SkeletonChipRow({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = SkeletonColors.of(context);
    final widths = [60.0, 90.0, 70.0, 100.0, 80.0];
    return SizedBox(
      height: AppSpace.v42,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.screenH),
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpace.v8),
        itemBuilder: (_, index) {
          return Container(
            width: widths[index % widths.length],
            height: AppSpace.v42,
            decoration: BoxDecoration(
              color: colors.base,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          );
        },
      ),
    );
  }
}
