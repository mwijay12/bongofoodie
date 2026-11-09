import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'bongo_glass_nav_bar.dart';

/// Keeps the branch navigator full height and the navigation above its content.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.body, required this.nav});

  final Widget body;
  final BongoGlassNavBar nav;

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(child: body),
          Positioned(
            left: AppSpace.lg,
            right: AppSpace.lg,
            bottom: AppSpace.navBottomInset + safeBottom,
            child: AnimatedSlide(
              offset: keyboardOpen ? const Offset(0, 2.5) : Offset.zero,
              duration: reduceMotion ? Duration.zero : AppMotion.base,
              curve: AppMotion.enter,
              child: IgnorePointer(
                ignoring: keyboardOpen,
                child: ExcludeSemantics(
                  excluding: keyboardOpen,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: AppSpace.navMaxWidth),
                      child: nav,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
