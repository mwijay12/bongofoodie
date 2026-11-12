import 'package:flutter/material.dart';
import '../../theme/app_tokens.dart';
import '../../theme/skeleton_colors.dart';
import 'skeleton_box.dart';

/// Mirrors PromoOfferCard: badge, title, then a copy+artwork row and action.
class SkeletonPromoCard extends StatelessWidget {
  const SkeletonPromoCard({super.key});

  @override
  Widget build(BuildContext context) => MediaQuery.withClampedTextScaling(
        maxScaleFactor: PromoCardMetrics.maxTextScale,
        child: Container(
          width: PromoCardMetrics.width,
          height: PromoCardMetrics.heightFor(context),
          padding: const EdgeInsets.all(PromoCardMetrics.padding),
          decoration: BoxDecoration(
              color: SkeletonColors.of(context).base,
              borderRadius:
                  BorderRadius.circular(PromoCardMetrics.borderRadius)),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(
                    width: AppSpace.v80,
                    height: AppSpace.md,
                    radius: AppRadius.pill),
                const SizedBox(height: AppSpace.v4),
                const SkeletonBox(height: AppSpace.md),
                const SizedBox(height: AppSpace.v4),
                Expanded(
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                      const Expanded(child: SkeletonLines(count: 2)),
                      const SizedBox(width: PromoCardMetrics.imageGap),
                      const SkeletonBox(
                          width: PromoCardMetrics.imageSize,
                          height: PromoCardMetrics.imageSize,
                          radius: PromoCardMetrics.imageRadius),
                    ])),
                const SkeletonBox(width: AppSpace.v118, height: AppSpace.lg),
              ]),
        ),
      );
}
