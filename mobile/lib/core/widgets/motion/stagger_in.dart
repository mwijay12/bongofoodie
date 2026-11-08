import 'package:flutter/material.dart';
import '../../theme/app_tokens.dart';

/// Fade + slide driven by one screen-level [AnimationController].
/// Reduced motion returns the child unchanged.
class StaggerIn extends StatelessWidget {
  const StaggerIn({
    super.key,
    required this.animation,
    required this.child,
    this.index = 0,
    this.total = DishDetailMetrics.staggerItems,
  });

  final Animation<double> animation;
  final Widget child;
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final safeTotal = total < 1 ? 1 : total;
    final start = (index / safeTotal * 0.5).clamp(0.0, 1.0);
    final end = (start + 0.5).clamp(0.0, 1.0);
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Interval(start, end, curve: AppMotion.enter),
        );
        return Opacity(
          opacity: curved.value,
          child: Transform.translate(
            offset: Offset(0, (1 - curved.value) * AppMotion.staggerOffset),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
