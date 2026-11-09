import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Return to the actual caller; a direct dish link returns to the menu.
void backFromDish(BuildContext context) {
  final router = GoRouter.maybeOf(context);
  if (router == null) return;
  if (router.canPop()) {
    router.pop();
  } else {
    router.go('/search');
  }
}

class DishBackScope extends StatelessWidget {
  const DishBackScope({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    return PopScope<Object?>(
      canPop: router?.canPop() ?? true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) backFromDish(context);
      },
      child: child,
    );
  }
}
