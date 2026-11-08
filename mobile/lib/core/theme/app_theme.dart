import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_colors.dart';
import 'app_tokens.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  static const _prefKey = 'bongo_theme_mode_v2';

  ThemeModeNotifier() : super(ThemeMode.light) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    if (saved == 'dark') {
      state = ThemeMode.dark;
    } else if (saved == 'light') {
      state = ThemeMode.light;
    }
  }

  Future<void> toggle() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, next == ThemeMode.dark ? 'dark' : 'light');
  }
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.primary).copyWith(
    primary: AppColors.cta, onPrimary: AppColors.surface,
    primaryContainer: AppColors.primarySoft, onPrimaryContainer: AppColors.primaryDeep,
    secondary: AppColors.spiceGreen, surface: AppColors.surface,
    onSurface: AppColors.ink, onSurfaceVariant: AppColors.inkMuted,
    outline: AppColors.outline, error: AppColors.danger,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme, fontFamily: 'Quicksand');
  final t = base.textTheme.apply(bodyColor: AppColors.ink, displayColor: AppColors.ink);
  final button = ElevatedButton.styleFrom(
    backgroundColor: AppColors.cta, foregroundColor: AppColors.surface,
    elevation: 0, minimumSize: const Size(44, 56), shape: const StadiumBorder(),
    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
  );
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.cream,
    appBarTheme: const AppBarTheme(backgroundColor: AppColors.cream,
      foregroundColor: AppColors.ink, elevation: 0, scrolledUnderElevation: 0),
    textTheme: t.copyWith(
      displaySmall: t.displaySmall?.copyWith(fontSize: 34, height: 1.1, fontWeight: FontWeight.w700, letterSpacing: -.8),
      headlineMedium: t.headlineMedium?.copyWith(fontSize: 26, height: 1.15, fontWeight: FontWeight.w700, letterSpacing: -.4),
      titleLarge: t.titleLarge?.copyWith(fontSize: 21, fontWeight: FontWeight.w700),
      titleMedium: t.titleMedium?.copyWith(fontSize: 17, fontWeight: FontWeight.w600),
      bodyLarge: t.bodyLarge?.copyWith(fontSize: 16, height: 1.5),
      bodyMedium: t.bodyMedium?.copyWith(fontSize: 14, height: 1.5, color: AppColors.inkMuted),
      labelLarge: t.labelLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
      labelSmall: t.labelSmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.4, color: AppColors.primaryDeep),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    }),
    elevatedButtonTheme: ElevatedButtonThemeData(style: button),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
      backgroundColor: AppColors.cta, foregroundColor: AppColors.surface,
      minimumSize: const Size.fromHeight(56), shape: const StadiumBorder(),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
    outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.ink, minimumSize: const Size.fromHeight(56),
      shape: const StadiumBorder(), side: const BorderSide(color: AppColors.outline, width: 1.5))),
    bottomSheetTheme: const BottomSheetThemeData(backgroundColor: AppColors.surface,
      showDragHandle: true, shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)))),
    chipTheme: ChipThemeData(backgroundColor: AppColors.surfaceWarm,
      selectedColor: AppColors.primarySoft, side: BorderSide.none,
      shape: const StadiumBorder(), labelStyle: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink)),
    inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: AppColors.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.outline))),
    dividerTheme: const DividerThemeData(color: AppColors.outline, thickness: 1),
  );
}

class AppTheme {
  AppTheme._();
  static ThemeData light() => buildAppTheme();
  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(seedColor: AppColors.primary,
      brightness: Brightness.dark, surface: AppColors.darkSurface,
      primary: AppColors.primary, secondary: AppColors.gold, error: AppColors.danger);
    return ThemeData(useMaterial3: true, fontFamily: 'Quicksand',
      colorScheme: scheme, scaffoldBackgroundColor: AppColors.darkBackground,
      appBarTheme: const AppBarTheme(backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.surface, elevation: 0, scrolledUnderElevation: 0),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.cta, foregroundColor: AppColors.surface,
        minimumSize: const Size(44, 56), shape: const StadiumBorder())),
    );
  }
}
