import 'dart:async';

import 'package:bongo_foodie/core/widgets/skeleton/shimmer.dart';
import 'package:bongo_foodie/core/widgets/skeleton/skeleton_box.dart';
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
  }
}
