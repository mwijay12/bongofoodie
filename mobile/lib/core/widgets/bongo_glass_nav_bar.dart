import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_tokens.dart';
import '../theme/app_colors.dart';

/// Floating navigation with equal, accessible targets even on narrow screens.
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final foreground = dark ? AppColors.surface : AppColors.deepCharcoal;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                boxShadow: [BoxShadow(
                  color: AppColors.scrim.withOpacity(dark ? .28 : .10),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                )],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    height: 70,
                    decoration: BoxDecoration(
                      color: (dark ? AppColors.navDark : AppColors.surface).withOpacity(.92),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: dark ? AppColors.surface.withOpacity(0.12) : AppColors.surface),
                    ),
                    child: Row(
                      children: List.generate(icons.length, (index) {
                        final selected = index == currentIndex;
                        final color = selected
                            ? (dark ? AppColors.goldenAmber : AppColors.primaryDark)
                            : foreground.withOpacity(.65);
                        return Expanded(
                          child: Semantics(
                            label: index == 3 && cartCount > 0
                                ? '${names[index]}, $cartCount items' : names[index],
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
                                      AnimatedContainer(
                                        duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 220),
                                        curve: Curves.easeOutCubic,
                                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: AppSpace.xs),
                                        decoration: BoxDecoration(
                                          color: selected ? AppColors.primary.withOpacity(.14) : AppColors.clear,
                                          borderRadius: BorderRadius.circular(AppRadius.md),
                                        ),
                                        child: Stack(clipBehavior: Clip.none, children: [
                                          Icon(icons[index], size: 21, color: color),
                                          if (index == 3 && cartCount > 0)
                                            Positioned(
                                              right: -10,
                                              top: -7,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs, vertical: 1),
                                                decoration: BoxDecoration(color: AppColors.primaryDark,
                                                  borderRadius: BorderRadius.circular(10)),
                                                child: Text(cartCount > 99 ? '99+' : '$cartCount',
                                                  style: const TextStyle(color: AppColors.surface, fontSize: 9,
                                                    fontWeight: FontWeight.w700)),
                                              ),
                                            ),
                                        ]),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(names[index], maxLines: 1, overflow: TextOverflow.ellipsis,
                                        textScaler: TextScaler.linear(
                                          (MediaQuery.textScalerOf(context).scale(10) / 10).clamp(1.0, 1.2).toDouble()),
                                        style: TextStyle(color: color, fontSize: 10,
                                          fontWeight: selected ? FontWeight.w700 : FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
