import 'dart:async';

import 'package:bongo_foodie/core/l10n/app_strings.dart';
import 'package:bongo_foodie/core/widgets/skeleton/shimmer.dart';
import 'package:bongo_foodie/core/widgets/skeleton/skeleton_box.dart';
import 'package:bongo_foodie/core/widgets/skeleton/skeleton_dish_card.dart';
import 'package:bongo_foodie/core/widgets/skeleton/skeleton_promo_card.dart';
import 'package:bongo_foodie/data/mock/showcase_seed_data.dart';
import 'package:bongo_foodie/data/models/models.dart';
import 'package:bongo_foodie/data/repositories/menu_repository.dart';
import 'package:bongo_foodie/features/home/home_screen.dart';
import 'package:bongo_foodie/features/menu/search_menu_screen.dart';
import 'package:bongo_foodie/state/menu_provider.dart';
import 'package:bongo_foodie/state/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _englishStrings = AppStrings(AppLanguage.en);

Future<void> _scrollHomeToBottom(WidgetTester tester) async {
  await tester.drag(
    find.byType(CustomScrollView).first,
    const Offset(0, -2000),
  );
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _disposeTree(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('menu loading uses skeleton instead of spinner ($brightness)',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final pending = Completer<List<MenuItemModel>>();
      await tester.pumpWidget(ProviderScope(
        overrides: [
          appStringsProvider.overrideWithValue(_englishStrings),
          showcaseLatencyProvider.overrideWithValue(Duration.zero),
          allMenuItemsProvider.overrideWith((ref) => pending.future),
          promotionsProvider.overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: const SearchMenuScreen(),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(Shimmer), findsWidgets);
      expect(find.byType(SkeletonBox), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      pending.complete([]);
      await tester.pump(const Duration(milliseconds: 100));
      await _disposeTree(tester);
    });

    testWidgets('home signature loading uses skeleton instead of spinner ($brightness)',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final pending = Completer<List<MenuItemModel>>();
      await tester.pumpWidget(ProviderScope(
        overrides: [
          appStringsProvider.overrideWithValue(_englishStrings),
          showcaseLatencyProvider.overrideWithValue(Duration.zero),
          allMenuItemsProvider.overrideWith((ref) => pending.future),
          promotionsProvider.overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: const HomeScreen(),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      await _scrollHomeToBottom(tester);
      expect(find.byType(Shimmer), findsWidgets);
      expect(find.byType(SkeletonBox), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      pending.complete([]);
      await tester.pump(const Duration(milliseconds: 100));
      await _disposeTree(tester);
    });

    testWidgets('home menu error shows retry button ($brightness)',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(ProviderScope(
        overrides: [
          appStringsProvider.overrideWithValue(_englishStrings),
          showcaseLatencyProvider.overrideWithValue(Duration.zero),
          allMenuItemsProvider.overrideWith((ref) => Future.error('boom')),
          promotionsProvider.overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: const HomeScreen(),
        ),
      ));
      await tester.pumpAndSettle();
      await _scrollHomeToBottom(tester);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(SkeletonDishCard), findsNothing);
      expect(find.text('Try again'), findsWidgets);
      await tester.ensureVisible(find.text('Try again').first);
      await tester.tap(find.text('Try again').first);
      await tester.pumpAndSettle();
      await _scrollHomeToBottom(tester);
      expect(find.text('Try again'), findsWidgets);
      await _disposeTree(tester);
    });

    testWidgets('home shows promo and dish skeletons during loading ($brightness)',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final pendingMenu = Completer<List<MenuItemModel>>();
      final pendingPromos = Completer<List<PromotionModel>>();
      await tester.pumpWidget(ProviderScope(
        overrides: [
          appStringsProvider.overrideWithValue(_englishStrings),
          showcaseLatencyProvider.overrideWithValue(Duration.zero),
          allMenuItemsProvider.overrideWith((ref) => pendingMenu.future),
          promotionsProvider.overrideWith((ref) => pendingPromos.future),
        ],
        child: MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: const HomeScreen(),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(SkeletonPromoCard), findsWidgets);
      await _scrollHomeToBottom(tester);
      expect(find.byType(SkeletonDishCard), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      pendingPromos.complete([]);
      pendingMenu.complete([]);
      await tester.pump(const Duration(milliseconds: 100));
      await _disposeTree(tester);
    });

    testWidgets('menu empty without query shows empty state ($brightness)',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(ProviderScope(
        overrides: [
          appStringsProvider.overrideWithValue(_englishStrings),
          showcaseLatencyProvider.overrideWithValue(Duration.zero),
          allMenuItemsProvider.overrideWith((ref) async => []),
          categoriesProvider.overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: const SearchMenuScreen(initialCategory: 'All'),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(SkeletonDishCard), findsNothing);
      expect(find.text('No dishes found'), findsWidgets);
      await _disposeTree(tester);
    });

    testWidgets('menu empty with query shows no results ($brightness)',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(ProviderScope(
        overrides: [
          appStringsProvider.overrideWithValue(_englishStrings),
          showcaseLatencyProvider.overrideWithValue(Duration.zero),
          allMenuItemsProvider.overrideWith(
            (ref) async => [ShowcaseSeedData.menuItems.first],
          ),
          categoriesProvider.overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: const SearchMenuScreen(initialCategory: 'All'),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byType(TextField), 'nonexistent dish xyz');
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('No matching dishes found'), findsWidgets);
      await _disposeTree(tester);
    });
  }
}
