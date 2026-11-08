import 'dart:async';

import 'package:bongo_foodie/core/widgets/skeleton/shimmer.dart';
import 'package:bongo_foodie/core/widgets/skeleton/skeleton_box.dart';
import 'package:bongo_foodie/core/widgets/skeleton/skeleton_dish_card.dart';
import 'package:bongo_foodie/core/widgets/skeleton/skeleton_promo_card.dart';
import 'package:bongo_foodie/data/models/models.dart';
import 'package:bongo_foodie/data/repositories/menu_repository.dart';
import 'package:bongo_foodie/features/home/home_screen.dart';
import 'package:bongo_foodie/features/menu/search_menu_screen.dart';
import 'package:bongo_foodie/state/menu_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('menu loading uses skeleton instead of spinner ($brightness)',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final pending = Completer<List<MenuItemModel>>();
      await tester.pumpWidget(ProviderScope(
        overrides: [
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
      await tester.pumpWidget(const SizedBox.shrink());
      pending.complete([]);
      await tester.pump();
    });

    testWidgets('home signature loading uses skeleton instead of spinner ($brightness)',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final pending = Completer<List<MenuItemModel>>();
      await tester.pumpWidget(ProviderScope(
        overrides: [
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
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -700));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(Shimmer), findsWidgets);
      expect(find.byType(SkeletonBox), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      pending.complete([]);
      await tester.pump();
    });

    testWidgets('home menu error shows retry button ($brightness)',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(ProviderScope(
        overrides: [
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
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(SkeletonDishCard), findsNothing);
      expect(find.text('Try again'), findsWidgets);
      await tester.tap(find.text('Try again').first);
      await tester.pumpAndSettle();
      expect(find.text('Try again'), findsWidgets);
    });

    testWidgets('home shows promo and dish skeletons during loading ($brightness)',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final pendingMenu = Completer<List<MenuItemModel>>();
      final pendingPromos = Completer<List<dynamic>>();
      await tester.pumpWidget(ProviderScope(
        overrides: [
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
      expect(find.byType(SkeletonDishCard), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      pendingPromos.complete([]);
      pendingMenu.complete([]);
      await tester.pumpAndSettle();
    });

    testWidgets('menu empty without query shows empty state ($brightness)',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(ProviderScope(
        overrides: [
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
    });

    testWidgets('menu empty with query shows no results ($brightness)',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final pendingMenu = Completer<List<MenuItemModel>>();
      await tester.pumpWidget(ProviderScope(
        overrides: [
          showcaseLatencyProvider.overrideWithValue(Duration.zero),
          allMenuItemsProvider.overrideWith((ref) => pendingMenu.future),
          categoriesProvider.overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: const SearchMenuScreen(initialCategory: 'All'),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'nonexistent dish xyz');
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('No matching dishes found'), findsWidgets);
      pendingMenu.complete([]);
      await tester.pumpAndSettle();
    });
  }
}
