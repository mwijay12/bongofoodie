import 'package:flutter/material.dart';
import '../../theme/app_tokens.dart';
import '../../theme/skeleton_colors.dart';

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = AppRadius.sm,
    this.circle = false,
  });

  final double? width;
  final double height;
  final double radius;
  final bool circle;

  @override
  Widget build(BuildContext context) => Container(
        width: circle ? (width ?? height) : width,
        height: height,
        decoration: BoxDecoration(
          color: SkeletonColors.of(context).base,
          shape: circle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: circle ? null : BorderRadius.circular(radius),
        ),
      );
}

class SkeletonLines extends StatelessWidget {
  const SkeletonLines({super.key, this.count = 2});
  final int count;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(height: AppSpace.sm),
            if (i == count - 1)
              const FractionallySizedBox(
                widthFactor: 0.6,
                child: SkeletonBox(height: AppSpace.md),
              )
            else
              const SkeletonBox(height: AppSpace.md),
          ],
        ],
      );
}
