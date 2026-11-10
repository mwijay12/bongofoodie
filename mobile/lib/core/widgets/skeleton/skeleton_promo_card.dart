import 'package:flutter/material.dart';
import '../../theme/app_tokens.dart';
import '../../theme/skeleton_colors.dart';
import 'skeleton_box.dart';

/// Mirrors PromoOfferCard's image row, full-width copy and action footprint.
class SkeletonPromoCard extends StatelessWidget {
  const SkeletonPromoCard({super.key});

  @override
  Widget build(BuildContext context) => Container(
        width: PromoCardMetrics.width,
        height: PromoCardMetrics.height,
        padding: const EdgeInsets.all(PromoCardMetrics.padding),
        decoration: BoxDecoration(
            color: SkeletonColors.of(context).base,
            borderRadius: BorderRadius.circular(PromoCardMetrics.borderRadius)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
              height: PromoCardMetrics.imageSize,
              child: Row(children: [
                const Expanded(
                    child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(
                        width: AppSpace.v80,
                        height: AppSpace.md,
                        radius: AppRadius.pill),
                    SizedBox(height: AppSpace.sm),
                    SkeletonLines(count: 3),
                  ],
                )),
                const SizedBox(width: PromoCardMetrics.imageGap),
                const SkeletonBox(
                    width: PromoCardMetrics.imageSize,
                    height: PromoCardMetrics.imageSize,
                    radius: PromoCardMetrics.imageRadius),
              ])),
          const SizedBox(height: AppSpace.v10),
          const SkeletonLines(count: 3),
          const Spacer(),
          const SkeletonBox(width: AppSpace.v118, height: AppSpace.lg),
        ]),
      );
}
