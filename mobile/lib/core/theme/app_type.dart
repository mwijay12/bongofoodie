/// Readable typography constants shared by the theme, text scaler and profile
/// control. The floor is 14dp for body-adjacent copy; display sizes stay larger.
abstract final class AppType {
  static const double normalTextScale = 1.0;
  static const double largeTextScale = 1.125;
  static const double largerTextScale = 1.25;

  /// OS accessibility scaling is honoured up to this ceiling so layouts that
  /// were tested at 1.3 do not become unbounded on heavily zoomed devices.
  static const double maxTextScale = 1.6;
  static const double minReadableFontSize = 14;

  static const double displayLarge = 40;
  static const double displayMedium = 36;
  static const double displaySmall = 32;
  static const double headlineLarge = 30;
  static const double headlineMedium = 26;
  static const double headlineSmall = 23;
  static const double titleLarge = 21;
  static const double titleMedium = 17;
  static const double titleSmall = 15;
  static const double bodyLarge = 16;
  static const double bodyMedium = 15;
  static const double bodySmall = 14;
  static const double labelLarge = 15;
  static const double labelMedium = 14;
  static const double labelSmall = 14;
}
