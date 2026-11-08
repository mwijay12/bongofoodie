import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/dish_image.dart';
import '../../data/models/models.dart';
import '../../state/auth_provider.dart';
import '../../state/settings_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _pageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishToSignIn() async {
    await ref.read(appSettingsProvider.notifier).completeOnboarding();
    if (mounted) context.go('/sign-in');
  }

  Future<void> _instantExplore() async {
    await ref.read(appSettingsProvider.notifier).completeOnboarding();
    final ok =
        await ref.read(authProvider.notifier).signInDemo(UserRole.customer);
    if (ok && mounted) {
      context.go('/home');
    }
  }

  void _showTermsSheet(AppStrings t) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.isSw
                  ? 'Masharti na Faragha ya BongoFoodie'
                  : 'BongoFoodie Terms & Privacy',
              style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              t.isSw
                  ? 'BongoFoodie inalinda taarifa zako kwa kutumia Supabase Row-Level Security (RLS). Malipo ya Lipa Namba na Pesa Taslimu yanathibitishwa papo hapo na timu yetu ya Kijitonyama, Dar es Salaam.'
                  : 'BongoFoodie safeguards your account and order history using strict Supabase Row-Level Security (RLS). Lipa Namba & Cash on Delivery orders are verified directly by our Kijitonyama, Dar es Salaam kitchen dispatch.',
              style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(t.isSw ? 'Nimeelewa' : 'Got It'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final t = ref.watch(appStringsProvider);

    final slides = [
      (
        badge: t.isSw ? 'MAPISHI YA KISWAHILI HALISI' : 'AUTHENTIC SWAHILI CUISINE',
        title: t.isSw
            ? 'Ladha Halisi ya Tanzania Kiganjani Mwako'
            : 'Tanzania’s Finest Flavors, Delivered Hot',
        subtitle: t.isSw
            ? 'Kuanzia Nyama Choma ya mkaa, Pilau ya Kuku wa Kienyeji hadi Samaki wa Kupaka wa tui la nazi.'
            : 'From smoky charcoal Nyama Choma & spiced Zanzibar Pilau to velvety coconut Samaki wa Kupaka.',
        imageKey: 'nyamaChoma',
      ),
      (
        badge: t.isSw ? 'MPISHI AI WA KISWAHILI' : 'AI SWAHILI EXECUTIVE CHEF',
        title: t.isSw
            ? 'Buni Sahani Yako Maalum na Chef AI'
            : 'Co-Create Custom Dishes with Chef AI',
        subtitle: t.isSw
            ? 'Uliza siri za mapishi kwa Kiswahili au Kiingereza na uagize chakula chako maalum papo hapo.'
            : 'Chat in Kiswahili or English, invent your dream Swahili fusion plate, and order it straight from our kitchen.',
        imageKey: 'bongoChefMascot',
      ),
      (
        badge: t.isSw ? 'UFIKISHAJI WA HARAKA DAR - TZ' : 'FAST TANZANIA DELIVERY',
        title: t.isSw
            ? 'Fuatilia Oda Live & Lipa kwa Lipa Namba'
            : 'Live Order Tracking & Easy Lipa Namba',
        subtitle: t.isSw
            ? 'Chagua Mkoa, Wilaya na Kata yako, lipa kwa M-Pesa/Tigo Pesa au Pesa Taslimu mlangoni.'
            : 'Pick your exact Region, District & Ward, pay via Mobile Money Till or Cash on Delivery, and track every step live.',
        imageKey: 'pilauYaKuku',
      ),
    ];

    return Scaffold(
      body: Container(
        color: AppColors.cream,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl, vertical: 14),
            child: Column(
              children: [
                // Top Bar: Brand + EN/SW Toggle + Skip
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpace.sm),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(
                        Icons.local_fire_department_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'BongoFoodie',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 19,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      onTap: () =>
                          ref.read(appSettingsProvider.notifier).toggleLanguage(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpace.md, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceWarm,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: AppColors.outline,
                          ),
                        ),
                        child: Text(
                          settings.isSwahili ? '🇹🇿 SW' : '🇬🇧 EN',
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Carousel
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: slides.length,
                    onPageChanged: (idx) => setState(() => _pageIndex = idx),
                    itemBuilder: (context, index) {
                      final slide = slides[index];
                      return LayoutBuilder(
                        builder: (context, constraints) => SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: constraints.maxHeight),
                            child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 235,
                            width: 235,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.primary.withOpacity(0.38),
                                  AppColors.primary.withOpacity(0.03),
                                ],
                              ),
                            ),
                            child: DishImage(
                              imageRef: slide.imageKey,
                              width: 205,
                              height: 205,
                              borderRadius: 999,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.16),
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.35),
                              ),
                            ),
                            child: Text(
                              slide.badge,
                              style: const TextStyle(
                                color: AppColors.primaryDeep,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            slide.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            slide.subtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.inkMuted,
                              fontSize: 14.5,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Dots Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(slides.length, (i) {
                    final active = i == _pageIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
                      height: 8,
                      width: active ? 28 : 8,
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.primary
                            : AppColors.outline,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),

                // Primary CTA
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _instantExplore,
                    icon: const Icon(Icons.auto_awesome_rounded, size: 20),
                    label: Text(
                      t.isSw
                          ? 'Jaribu Showcase Demo Sasa'
                          : 'Launch Instant Showcase Demo',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      side: BorderSide(color: AppColors.outline),
                    ),
                    onPressed: () {
                      if (_pageIndex < slides.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                        );
                      } else {
                        _finishToSignIn();
                      }
                    },
                    child: Text(
                      _pageIndex < slides.length - 1
                          ? (t.isSw ? 'Endelea' : 'Next Story')
                          : (t.isSw
                              ? 'Ingia au Fungua Akaunti'
                              : 'Sign In / Create Account'),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => _showTermsSheet(t),
                  child: Text(
                    t.isSw
                        ? 'Masharti ya Huduma & Faragha • Dar es Salaam'
                        : 'Terms of Service & Privacy • Dar es Salaam',
                    style: TextStyle(
                      color: AppColors.inkMuted,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
