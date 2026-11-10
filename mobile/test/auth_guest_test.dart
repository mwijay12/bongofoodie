import 'package:bongo_foodie/core/l10n/app_strings.dart';
import 'package:bongo_foodie/core/theme/app_theme.dart';
import 'package:bongo_foodie/core/utils/auth_validation.dart';
import 'package:bongo_foodie/data/models/models.dart';
import 'package:bongo_foodie/data/repositories/auth_repository.dart';
import 'package:bongo_foodie/features/auth/sign_in_screen.dart';
import 'package:bongo_foodie/features/auth/sign_up_screen.dart';
import 'package:bongo_foodie/features/onboarding/onboarding_screen.dart';
import 'package:bongo_foodie/state/auth_provider.dart';
import 'package:bongo_foodie/state/cart_provider.dart';
import 'package:bongo_foodie/state/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Auth extends AuthRepository {
  int demoLogins = 0;
  int signups = 0;
  bool confirmation = false;
  @override
  Future<AppUser?> restoreSession() async => null;
  @override
  Future<AppUser> signInDemo(UserRole role) async {
    demoLogins++;
    return const AppUser(id: 'demo', name: 'Demo', email: 'demo@example.com');
  }

  @override
  Future<AppUser> signUpWithEmail(
      {required String name,
      required String email,
      required String password,
      String phone = ''}) async {
    signups++;
    if (confirmation) throw EmailConfirmationRequired(email);
    return AppUser(id: 'test-user', name: name, email: email, phone: phone);
  }
}

Future<ProviderContainer> pumpAuth(WidgetTester tester, Widget home,
    {required _Auth repo,
    Size size = const Size(360, 640),
    bool dark = false,
    AppLanguage language = AppLanguage.en}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer(overrides: [
    authRepositoryProvider.overrideWithValue(repo),
    appStringsProvider.overrideWithValue(AppStrings(language)),
  ]);
  addTearDown(container.dispose);
  final router = GoRouter(initialLocation: '/entry', routes: [
    GoRoute(path: '/entry', builder: (_, __) => home),
    GoRoute(
        path: '/home',
        builder: (_, __) => const Scaffold(body: Text('Guest Home'))),
    GoRoute(path: '/sign-in', builder: (_, __) => const SignInScreen()),
    GoRoute(path: '/sign-up', builder: (_, __) => const SignUpScreen()),
  ]);
  addTearDown(router.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
          routerConfig: router,
          theme: dark ? AppTheme.dark() : buildAppTheme(),
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(1.3),
                  disableAnimations: true),
              child: child!))));
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
  return container;
}

Future<void> disposeTree(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  test('auth input checks accept TZ formats and reject malformed values', () {
    expect(isValidAuthEmail(' person@example.com '), isTrue);
    expect(isValidAuthEmail('not@valid'), isFalse);
    expect(isValidAuthEmail('a b@example.com'), isFalse);
    for (final phone in ['0712 345 678', '+255 712 345 678', '255712345678']) {
      expect(isValidTzPhone(phone), isTrue);
    }
    for (final phone in ['', '+255 ', '123', '+254712345678']) {
      expect(isValidTzPhone(phone), isFalse);
    }
  });
  for (final entry in <String, Widget>{
    'onboarding': const OnboardingScreen(),
    'sign-in': const SignInScreen(),
    'sign-up': const SignUpScreen()
  }.entries) {
    testWidgets(
        '${entry.key} guest does not create a demo identity or lose cart',
        (tester) async {
      final repo = _Auth();
      final container = await pumpAuth(tester, entry.value, repo: repo);
      container.read(cartProvider.notifier).addItem(
          dish: const MenuItemModel(
              id: 'dish',
              name: 'Pilau',
              description: '',
              imageUrl: '',
              price: 8000));
      final guest = find.text('Continue as guest');
      await tester.ensureVisible(guest);
      await tester.tap(guest);
      await tester.pump(Duration.zero);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Guest Home'), findsOneWidget);
      expect(container.read(authProvider).user, isNull);
      expect(repo.demoLogins, 0);
      expect(container.read(cartProvider).totalItems, 1);
      expect(container.read(appSettingsProvider).hasSeenOnboarding, isTrue);
      await disposeTree(tester);
    });
  }
  for (final size in [const Size(360, 640), const Size(430, 932)]) {
    for (final dark in [false, true]) {
      for (final language in AppLanguage.values) {
        for (final signup in [false, true]) {
          testWidgets('auth signup=$signup $size dark=$dark $language text1.3',
              (tester) async {
            await pumpAuth(
                tester, signup ? const SignUpScreen() : const SignInScreen(),
                repo: _Auth(), size: size, dark: dark, language: language);
            expect(tester.takeException(), isNull);
            for (var i = 0; i < 4; i++) {
              await tester.drag(find.byType(ListView), const Offset(0, -220));
              await tester.pump(const Duration(milliseconds: 100));
              expect(tester.takeException(), isNull);
            }
            final submit = find.byKey(const ValueKey('auth-submit'));
            await tester.ensureVisible(submit);
            await tester.tap(submit);
            await tester.pump(const Duration(milliseconds: 100));
            expect(tester.takeException(), isNull);
            await disposeTree(tester);
          });
        }
      }
    }
  }
  testWidgets('signup validates then remains signed out for email confirmation',
      (tester) async {
    final repo = _Auth()..confirmation = true;
    final container = await pumpAuth(tester, const SignUpScreen(), repo: repo);
    for (final pair in [
      ('auth-name', 'Amina Hassan'),
      ('auth-phone', '0712345678'),
      ('auth-email', 'amina@example.com'),
      ('auth-password', 'securepass')
    ]) {
      final field = find.byKey(ValueKey(pair.$1));
      await tester.scrollUntilVisible(field, 160,
          scrollable: find.byType(Scrollable).first);
      await tester.enterText(field, pair.$2);
    }
    final submit = find.byKey(const ValueKey('auth-submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump(const Duration(milliseconds: 100));
    expect(repo.signups, 1);
    expect(container.read(authProvider).user, isNull);
    expect(container.read(authProvider).confirmationEmail, 'amina@example.com');
    expect(find.textContaining('Check amina@example.com'), findsOneWidget);
    expect(find.text('Guest Home'), findsNothing);
    await disposeTree(tester);
  });
  test('offline signup cannot assign admin by email', () async {
    SharedPreferences.setMockInitialValues({});
    final user = await AuthRepository().signUpWithEmail(
        name: 'Test',
        email: 'defoodordering@gmail.com',
        password: 'securepass');
    expect(user.isDemo, isTrue);
    expect(user.role, UserRole.customer);
  });
}
