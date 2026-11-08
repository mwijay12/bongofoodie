import 'package:bongo_foodie/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets('root system overlay follows ${dark ? 'dark' : 'light'} theme',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'bongo_theme_dark_v2': dark,
        'bongo_onboarded_v2': true,
      });
      await tester.pumpWidget(const ProviderScope(child: BongoFoodieApp()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.byKey(const ValueKey('app-system-ui')),
      );
      expect(region.value.statusBarIconBrightness,
          dark ? Brightness.light : Brightness.dark);
      expect(region.value.statusBarColor, Colors.transparent);
      expect(region.value.systemNavigationBarColor, Colors.transparent);
      expect(region.value.systemNavigationBarContrastEnforced, isFalse);
    });
  }
}
