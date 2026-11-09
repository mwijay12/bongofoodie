import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_tokens.dart';
import '../core/widgets/bongo_glass_nav_bar.dart';
import '../core/widgets/app_shell.dart';
import '../features/auth/sign_in_screen.dart';
import '../features/auth/sign_up_screen.dart';
import '../features/cart/cart_screen.dart';
import '../features/chef_ai/chef_ai_screen.dart';
import '../features/home/home_screen.dart';
import '../features/menu/dish_detail_screen.dart';
import '../features/menu/search_menu_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/staff/staff_dispatch_screen.dart';
import '../state/auth_provider.dart';
import '../state/cart_provider.dart';
import '../state/settings_provider.dart';
import 'dish_route_args.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final settings = ref.watch(appSettingsProvider);
  final isAuthenticated =
      ref.watch(authProvider.select((s) => s.isAuthenticated));

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: !settings.hasSeenOnboarding && !isAuthenticated
        ? '/onboarding'
        : '/home',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/sign-up',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/staff',
        builder: (context, state) => const StaffDispatchScreen(),
      ),
      GoRoute(
        path: '/dish/:id',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final extra = state.extra;
          final args = extra is DishRouteArgs ? extra : null;
          return CustomTransitionPage<void>(
            key: state.pageKey,
            transitionDuration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : AppMotion.slow,
            reverseTransitionDuration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : AppMotion.base,
            transitionsBuilder: (context, animation, __, child) {
              if (MediaQuery.disableAnimationsOf(context)) return child;
              final curved = animation.drive(
                CurveTween(curve: AppMotion.enter),
              );
              return FadeTransition(
                opacity: curved,
                child: ScaleTransition(
                  scale: Tween<double>(
                    begin: AppMotion.transitionScaleBegin,
                    end: 1,
                  ).animate(curved),
                  child: child,
                ),
              );
            },
            child: DishDetailScreen(id: id, args: args),
          );
        },
      ),

      // Main 5-Tab Customer Shell (Zero ghost 6th tab!)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return _CustomerMainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                builder: (context, state) {
                  final cat = state.uri.queryParameters['category'] ?? 'All';
                  return SearchMenuScreen(initialCategory: cat);
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chef-ai',
                builder: (context, state) => const ChefAiScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/cart',
                builder: (context, state) => const CartScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class _CustomerMainShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const _CustomerMainShell({required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(appStringsProvider);
    final cartCount = ref.watch(cartProvider.select((c) => c.totalItems));

    return PopScope<Object?>(
      canPop: navigationShell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && navigationShell.currentIndex != 0) {
          navigationShell.goBranch(0);
        }
      },
      child: AppShell(
        body: navigationShell,
        nav: BongoGlassNavBar(
          currentIndex: navigationShell.currentIndex,
          cartCount: cartCount,
          labels: [
            t.navHome,
            t.navSearch,
            t.navChefAi,
            t.navCart,
            t.navProfile,
          ],
          onTap: (idx) {
            navigationShell.goBranch(
              idx,
              initialLocation: idx == navigationShell.currentIndex,
            );
          },
        ),
      ),
    );
  }
}
