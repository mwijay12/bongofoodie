import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bongo_foodie/core/l10n/app_strings.dart';
import 'package:bongo_foodie/core/theme/app_tokens.dart';
import 'package:bongo_foodie/core/widgets/async_skeleton.dart';
import 'package:bongo_foodie/core/widgets/skeleton/shimmer.dart';
import 'package:bongo_foodie/core/widgets/skeleton/skeleton_box.dart';
import 'package:bongo_foodie/state/settings_provider.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('loading, data and retry work in $brightness', (tester) async {
      var retries = 0;
      Widget host(AsyncValue<int> value) => ProviderScope(
            overrides: [appStringsProvider.overrideWithValue(const AppStrings(AppLanguage.en))],
            child: MaterialApp(
              theme: ThemeData(brightness: brightness),
              home: Scaffold(
                body: AsyncSkeleton<int>(
                  value: value,
                  data: (number) => Text('data $number'),
                  skeleton: const SkeletonBox(height: AppSpace.v20),
                  onRetry: () => retries++,
                ),
              ),
            ),
          );
      await tester.pumpWidget(host(const AsyncLoading<int>()));
      expect(find.byType(SkeletonBox), findsOneWidget);
      await tester.pumpWidget(host(const AsyncData<int>(7)));
      await tester.pump(AppMotion.slow);
      expect(find.text('data 7'), findsOneWidget);
      await tester.pumpWidget(host(AsyncError<int>(Exception('x'), StackTrace.empty)));
      await tester.pump(AppMotion.slow);
      await tester.tap(find.byType(FilledButton));
      expect(retries, 1);
    });

    testWidgets('reduced motion stops shimmer in $brightness', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Shimmer(child: SkeletonBox(height: AppSpace.v20)),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(SkeletonBox), findsOneWidget);
    });
  }
}
