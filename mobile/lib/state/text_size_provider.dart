import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_type.dart';

/// The in-app reading preference. This is deliberately a separate provider:
/// the existing settings state and public API stay untouched.
enum AppTextSize { normal, large, larger }

extension AppTextSizeX on AppTextSize {
  double get scaleFactor {
    switch (this) {
      case AppTextSize.normal:
        return AppType.normalTextScale;
      case AppTextSize.large:
        return AppType.largeTextScale;
      case AppTextSize.larger:
        return AppType.largerTextScale;
    }
  }

  String get storageValue => name;
}

AppTextSize appTextSizeFromStorage(String? value) {
  for (final size in AppTextSize.values) {
    if (size.storageValue == value) return size;
  }
  return AppTextSize.normal;
}

final textSizeProvider =
    StateNotifierProvider<TextSizeNotifier, AppTextSize>((ref) {
  return TextSizeNotifier();
});

class TextSizeNotifier extends StateNotifier<AppTextSize> {
  static const String storageKey = 'bongo_text_size_v1';

  TextSizeNotifier() : super(AppTextSize.normal) {
    _ready = _hydrate();
  }

  late final Future<void> _ready;

  /// Exposed so tests can wait for hydration instead of guessing a delay.
  Future<void> get ready => _ready;

  bool _edited = false;

  Future<void> _hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted || _edited) return;
    state = appTextSizeFromStorage(prefs.getString(storageKey));
  }

  Future<void> setTextSize(AppTextSize size) async {
    _edited = true;
    state = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, size.storageValue);
  }
}
