import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/l10n/app_strings.dart';

class AppSettingsState {
  final ThemeMode themeMode;
  final AppLanguage language;
  final bool hasSeenOnboarding;
  final bool isReady;

  const AppSettingsState({
    this.themeMode = ThemeMode.light,
    this.language = AppLanguage.en,
    this.hasSeenOnboarding = false,
    this.isReady = false,
  });

  bool get isDark => themeMode == ThemeMode.dark;
  bool get isSwahili => language == AppLanguage.sw;

  AppSettingsState copyWith({
    ThemeMode? themeMode,
    AppLanguage? language,
    bool? hasSeenOnboarding,
    bool? isReady,
  }) {
    return AppSettingsState(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
      isReady: isReady ?? this.isReady,
    );
  }
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettingsState>((ref) {
  return AppSettingsNotifier();
});

final appStringsProvider = Provider<AppStrings>((ref) {
  final lang = ref.watch(appSettingsProvider.select((s) => s.language));
  return AppStrings(lang);
});

class AppSettingsNotifier extends StateNotifier<AppSettingsState> {
  static const _themeKey = 'bongo_theme_dark_v2';
  static const _langKey = 'bongo_lang_v2';
  static const _onboardedKey = 'bongo_onboarded_v2';

  AppSettingsNotifier() : super(const AppSettingsState()) {
    _hydrate();
  }

  bool _themeEdited = false;
  bool _languageEdited = false;
  bool _onboardingEdited = false;

  Future<void> _hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_themeKey) ?? false;
    final langRaw = prefs.getString(_langKey) ?? 'en';
    final seenOnboarding = prefs.getBool(_onboardedKey) ?? false;

    if (!mounted) return;
    state = AppSettingsState(
      themeMode: _themeEdited
          ? state.themeMode
          : (isDark ? ThemeMode.dark : ThemeMode.light),
      language: _languageEdited
          ? state.language
          : (langRaw == 'sw' ? AppLanguage.sw : AppLanguage.en),
      hasSeenOnboarding:
          _onboardingEdited ? state.hasSeenOnboarding : seenOnboarding,
      isReady: true,
    );
  }

  Future<void> toggleDarkMode(bool enabled) async {
    _themeEdited = true;
    state = state.copyWith(
      themeMode: enabled ? ThemeMode.dark : ThemeMode.light,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, enabled);
  }

  Future<void> setLanguage(AppLanguage lang) async {
    _languageEdited = true;
    state = state.copyWith(language: lang);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, lang == AppLanguage.sw ? 'sw' : 'en');
  }

  Future<void> toggleLanguage() async {
    final next =
        state.language == AppLanguage.en ? AppLanguage.sw : AppLanguage.en;
    await setLanguage(next);
  }

  Future<void> completeOnboarding() async {
    _onboardingEdited = true;
    state = state.copyWith(hasSeenOnboarding: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardedKey, true);
  }
}
