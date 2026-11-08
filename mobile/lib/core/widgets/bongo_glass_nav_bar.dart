import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// Floating navigation with equally sized targets and an animated selection.
class BongoGlassNavBar extends StatelessWidget {
  final int currentIndex;
  final int cartCount;
  final ValueChanged<int> onTap;
  final List<String>? labels;

  const BongoGlassNavBar({
    super.key,
    required this.currentIndex,
    required this.cartCount,
    required this.onTap,
    this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final names = labels != null && labels!.length == 5
        ? labels!
        : const ['Home', 'Menu', 'Chef AI', 'Cart', 'Profile'];
    const icons = [
      Icons.home_rounded,
      Icons.search_rounded,
      Icons.auto_awesome_rounded,
      Icons.shopping_bag_rounded,
      Icons.person_rounded,
    ];
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final duration = reduceMotion ? Duration.zero : AppMotion.base;
    final glass = dark ? AppColors.navDark : scheme.surface;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.lifted,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: AppSpace.lg, sigmaY: AppSpace.lg),
          child: Container(
            height: AppSpace.navHeight,
            padding: const EdgeInsets.all(AppSpace.xs),
            decoration: BoxDecoration(
              color: glass.withOpacity(.92),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: scheme.outline.withOpacity(.45)),
            ),
            child: LayoutBuilder(builder: (context, constraints) {
              final itemWidth = constraints.maxWidth / icons.length;
              return Stack(children: [
                AnimatedPositioned(
                  duration: duration,
                  curve: AppMotion.enter,
                  left: currentIndex * itemWidth,
                  width: itemWidth,
                  top: 0,
                  bottom: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
                Row(children: List.generate(icons.length, (index) {
                  final selected = index == currentIndex;
                  final color = selected
                      ? scheme.onPrimaryContainer
                      : scheme.onSurfaceVariant;
                  final badge = index == 3 ? cartCount : 0;
                  return Expanded(
                    child: Semantics(
                      label: badge > 0 ? '${names[index]}, $badge items' : names[index],
                      selected: selected,
                      button: true,
                      child: Tooltip(
                        message: names[index],
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            onTap(index);
                          },
                          child: ExcludeSemantics(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Badge(
                                  isLabelVisible: badge > 0,
                                  label: Text(badge > 99 ? '99+' : '$badge'),
                                  child: Icon(icons[index], size: AppSpace.xl, color: color),
                                ),
                                const SizedBox(height: AppSpace.xxs),
                                Text(names[index], maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    letterSpacing: 0, color: color,
                                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                })),
              ]);
            }),
          ),
        ),
      ),
    );
  }
}
