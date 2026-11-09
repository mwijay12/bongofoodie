import 'package:bongo_foodie/core/icons/app_icon_key.dart';
import 'package:bongo_foodie/core/l10n/app_strings.dart';
import 'package:bongo_foodie/core/theme/app_theme.dart';
import 'package:bongo_foodie/core/utils/emoji_sanitizer.dart';
import 'package:bongo_foodie/data/models/models.dart';
import 'package:bongo_foodie/data/repositories/menu_repository.dart';
import 'package:bongo_foodie/features/chef_ai/chef_ai_screen.dart';
import 'package:bongo_foodie/features/home/home_screen.dart';
import 'package:bongo_foodie/features/staff/staff_dispatch_screen.dart';
import 'package:bongo_foodie/state/menu_provider.dart';
import 'package:bongo_foodie/state/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Code points are built numerically so this test file holds no literal emoji.
String _cp(int codePoint) => String.fromCharCode(codePoint);

bool _hasEmoji(String value) {
  for (final rune in value.runes) {
    if ((rune >= 0x1F000 && rune <= 0x1FAFF) ||
        (rune >= 0x2600 && rune <= 0x27BF) ||
        (rune >= 0x2B00 && rune <= 0x2BFF) ||
        rune == 0xFE0F ||
        rune == 0x200D ||
        rune == 0x20E3) {
      return true;
    }
  }
  return false;
}

/// Collects every Text widget's plain data (also Text.rich) in the tree.
List<String> _allTextData(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((text) => text.data ?? text.textSpan?.toPlainText() ?? '')
    .toList();

/// A repository that returns legacy, emoji-bearing remote-looking rows. The
/// real repository sanitizes remote rows; Home also sanitizes promo copy.
class _EmojiSeedRepository extends MenuRepository {
  _EmojiSeedRepository() : super(showcaseLatency: Duration.zero);

  @override
  Future<List<PromotionModel>> getPromotions() async => <PromotionModel>[
        PromotionModel(
          id: 'emoji-promo',
          title: 'KARIBU BONGO FEAST',
          subtitle: 'Save on any Swahili main dish',
          discountBadge: '${_cp(0x1F525)} TSh 2,000 OFF',
        ),
      ];

  @override
  Future<List<DiscoveryModel>> getDailyDiscoveries() async =>
      <DiscoveryModel>[
        DiscoveryModel(
          id: 'emoji-discovery',
          title: 'Zanzibar Spice Capital ${_cp(0x1F334)}',
          description: 'Cloves and cinnamon from Unguja.',
        ),
      ];
}

Widget _host(Widget home, List<Override> overrides) => ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: buildAppTheme(),
        home: home,
      ),
    );

Future<void> _pumpScreen(
  WidgetTester tester,
  Widget screen, {
  List<Override> overrides = const <Override>[],
}) async {
  tester.view.physicalSize = const Size(800, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(_host(screen, overrides));
  // Bounded pumps: the skeleton shimmer and tab tickers never settle.
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('stripEmoji', () {
    test('leaves plain text unchanged', () {
      expect(stripEmoji('Pilau ya Kuku'), 'Pilau ya Kuku');
    });

    test('removes a pictograph', () {
      expect(
        stripEmoji('Pilau ${_cp(0x1F35B)} ya Kuku'),
        'Pilau ya Kuku',
      );
    });

    test('removes a ZWJ sequence', () {
      final chef =
          _cp(0x1F468) + _cp(0x200D) + _cp(0x1F373);
      expect(stripEmoji('Karibu $chef leo'), 'Karibu leo');
    });

    test('removes a flag sequence', () {
      final tz = _cp(0x1F1F9) + _cp(0x1F1FF);
      expect(stripEmoji('BongoFoodie $tz'), 'BongoFoodie');
    });

    test('removes variation-selector and keycap sequences', () {
      expect(
        stripEmoji('${_cp(0x1F336)}${_cp(0xFE0F)} Pilipili'),
        'Pilipili',
      );
      expect(
        stripEmoji('1${_cp(0x20E3)} Chaguo'),
        '1 Chaguo',
      );
    });

    test('keeps Swahili accents and combining marks', () {
      const accented = 'Kilimanjaro, ñ, ā, ú, à, è, ę, ọ';
      expect(stripEmoji(accented), accented);
      expect(stripEmoji('Mama\u0301'), 'Mama\u0301');
    });

    test('collapses leftover double spaces and trims', () {
      expect(stripEmoji('Pilau  ni  nzuri'), 'Pilau ni nzuri');
      expect(
        stripEmoji('  ${_cp(0x1F525)}  OFF  '),
        'OFF',
      );
    });

    test('handles the empty string', () {
      expect(stripEmoji(''), '');
    });
  });

  group('screens contain no emoji glyphs', () {
    testWidgets('Staff Dispatch renders no emoji in any Text', (tester) async {
      await _pumpScreen(
        tester,
        const StaffDispatchScreen(),
        overrides: <Override>[
          showcaseLatencyProvider.overrideWithValue(Duration.zero),
        ],
      );
      expect(tester.takeException(), isNull);
      final texts = _allTextData(tester);
      expect(texts, isNotEmpty);
      for (final text in texts) {
        expect(_hasEmoji(text), isFalse, reason: 'emoji in Text: $text');
      }
    });

    testWidgets('Chef AI renders no emoji in any Text', (tester) async {
      await _pumpScreen(
        tester,
        const ChefAiScreen(),
        overrides: <Override>[
          showcaseLatencyProvider.overrideWithValue(Duration.zero),
          appStringsProvider.overrideWithValue(
            const AppStrings(AppLanguage.en),
          ),
        ],
      );
      expect(tester.takeException(), isNull);
      final texts = _allTextData(tester);
      expect(texts, isNotEmpty);
      for (final text in texts) {
        expect(_hasEmoji(text), isFalse, reason: 'emoji in Text: $text');
      }
    });
  });

  group('promo and discovery cards show icons instead of emoji', () {
    Future<void> pumpHome(WidgetTester tester) => _pumpScreen(
          tester,
          const HomeScreen(showEnvBadge: false),
          overrides: <Override>[
            menuRepositoryProvider.overrideWithValue(_EmojiSeedRepository()),
            showcaseLatencyProvider.overrideWithValue(Duration.zero),
            appStringsProvider.overrideWithValue(
              const AppStrings(AppLanguage.en),
            ),
            categoriesProvider.overrideWith(
              (ref) async => <CategoryModel>[],
            ),
            allMenuItemsProvider.overrideWith(
              (ref) async => <MenuItemModel>[],
            ),
          ],
        );

    testWidgets('promo badge renders an Icon and sanitised text',
        (tester) async {
      await pumpHome(tester);
      expect(tester.takeException(), isNull);
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Icon && widget.icon == AppIconKey.fire.icon,
        ),
        findsWidgets,
        reason: 'promo badge must show a fire Icon where the emoji was',
      );
      expect(find.text('TSh 2,000 OFF'), findsWidgets);
      expect(find.textContaining(_cp(0x1F525)), findsNothing);
    });

    testWidgets('discovery card renders an Icon for its emoji title',
        (tester) async {
      await pumpHome(tester);
      expect(tester.takeException(), isNull);
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Icon &&
              (widget.icon == AppIconKey.eco.icon ||
                  widget.icon == AppIconKey.idea.icon),
        ),
        findsWidgets,
        reason: 'discovery card must show an Icon where the emoji was',
      );
    });
  });
}
