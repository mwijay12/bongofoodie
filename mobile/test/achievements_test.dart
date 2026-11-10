import 'package:bongo_foodie/core/widgets/achievement_cards.dart';
import 'package:bongo_foodie/core/theme/app_theme.dart';
import 'package:bongo_foodie/state/achievements_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('thresholds have no default unlock and ignore unfinished milestones',
      () {
    expect(const AchievementProgress().unlockedCount, 0);
    expect(const AchievementProgress(ordersSubmitted: 1).unlockedCount, 1);
    expect(const AchievementProgress(ordersSubmitted: 2).unlockedCount, 1);
    expect(
        const AchievementProgress(ordersSubmitted: 3, correctQuizzes: 1)
            .unlockedCount,
        3);
  });
  test('server counts must be nonnegative finite integers', () {
    for (final bad in [-1, 0.5, double.nan, double.infinity, '3', null]) {
      expect(
          () => AchievementProgress.fromJson(
              {'orders_submitted': bad, 'correct_quizzes': 0}),
          throwsFormatException);
    }
  });
  for (final size in [const Size(360, 640), const Size(430, 932)]) {
    for (final sw in [false, true]) {
      for (final dark in [false, true]) {
        for (final earned in [false, true]) {
          testWidgets(
              'badge copy and art $size sw=$sw dark=$dark earned=$earned',
              (tester) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final semantics = tester.ensureSemantics();
            await tester.pumpWidget(MaterialApp(
                theme: dark ? AppTheme.dark() : buildAppTheme(),
                builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                        textScaler: const TextScaler.linear(1.3),
                        disableAnimations: true),
                    child: child!),
                home: Scaffold(
                    body: SingleChildScrollView(
                        child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: AchievementCards(
                                isSw: sw,
                                progress: earned
                                    ? const AchievementProgress(
                                        ordersSubmitted: 3, correctQuizzes: 1)
                                    : const AchievementProgress()))))));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(find.byType(Image), findsNWidgets(3));
            expect(find.text(sw ? 'Oda ya kwanza' : 'First order'),
                findsOneWidget);
            expect(
                find.bySemanticsLabel(
                    RegExp(sw ? 'Tuma oda moja' : 'Submit one order')),
                findsOneWidget);
            expect(
                find.textContaining(earned
                    ? (sw ? 'Imepatikana' : 'Earned')
                    : (sw ? 'Bado haijapatikana' : 'Not yet earned')),
                findsNWidgets(3));
            semantics.dispose();
            await tester.pumpWidget(const SizedBox.shrink());
          });
        }
      }
    }
  }
}
