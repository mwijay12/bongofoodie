import 'package:bongo_foodie/core/l10n/app_strings.dart';
import 'package:bongo_foodie/core/l10n/daily_copy.dart';
import 'package:bongo_foodie/core/theme/app_theme.dart';
import 'package:bongo_foodie/data/models/models.dart';
import 'package:bongo_foodie/data/repositories/menu_repository.dart';
import 'package:bongo_foodie/features/home/home_screen.dart';
import 'package:bongo_foodie/state/menu_provider.dart';
import 'package:bongo_foodie/state/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final size in [const Size(360, 640), const Size(430, 932)]) {
    for (final dark in [false, true]) {
      for (final sw in [false, true]) {
        testWidgets('daily copy and scrollable quiz $size dark=$dark sw=$sw',
            (tester) async {
          SharedPreferences.setMockInitialValues({});
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final strings = AppStrings(sw ? AppLanguage.sw : AppLanguage.en);
          await tester.pumpWidget(ProviderScope(
              overrides: [
                appStringsProvider.overrideWithValue(strings),
                showcaseLatencyProvider.overrideWithValue(Duration.zero),
                promotionsProvider
                    .overrideWith((ref) async => <PromotionModel>[]),
                allMenuItemsProvider
                    .overrideWith((ref) async => <MenuItemModel>[]),
                categoriesProvider
                    .overrideWith((ref) async => <CategoryModel>[]),
              ],
              child: MaterialApp(
                  theme: dark ? AppTheme.dark() : buildAppTheme(),
                  builder: (context, child) => MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                          textScaler: const TextScaler.linear(1.3),
                          disableAnimations: true),
                      child: child!),
                  home: const HomeScreen(showEnvBadge: false))));
          await tester.pumpAndSettle();
          await tester.scrollUntilVisible(
              find.text(strings.playSpiceTrivia), 150,
              scrollable: find.byType(Scrollable).first);
          expect(tester.takeException(), isNull);
          final copy = sw ? DailyCopy.discoveriesSw : DailyCopy.discoveries;
          expect(copy.any((d) => find.text(d.title).evaluate().isNotEmpty),
              isTrue);
          await tester.tap(find.text(strings.playSpiceTrivia));
          await tester.pumpAndSettle();
          expect(
              find.text(sw ? 'Swali la leo kuhusu chakula' : 'Daily food quiz'),
              findsOneWidget);
          expect(tester.takeException(), isNull);
          final questions = sw ? DailyCopy.triviaSw : DailyCopy.trivia;
          expect(
              questions.any((q) => find.text(q.question).evaluate().isNotEmpty),
              isTrue);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        });
      }
    }
  }
}
