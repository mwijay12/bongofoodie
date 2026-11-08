import 'package:flutter/material.dart';

/// The Warm Swahili Luxury palette. Use semantic tokens instead of raw colors.
abstract final class AppColors {
  static const primary = Color(0xFFF58220);
  static const cta = Color(0xFFDE6208);
  static const primarySoft = Color(0xFFFDE8D3);
  static const primaryDeep = Color(0xFFB04A05);
  static const cream = Color(0xFFFAF7F2);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceWarm = Color(0xFFF4EEE6);
  static const outline = Color(0xFFEADFD2);
  static const ink = Color(0xFF2B1B12);
  static const inkMuted = Color(0xFF6F645D);
  static const ember = Color(0xFF1A100B);
  static const spiceGreen = Color(0xFF11543A);
  static const spiceGreenSoft = Color(0xFFDDEFE5);
  static const gold = Color(0xFFF2B33D);
  static const success = Color(0xFF1F9D55);
  static const danger = Color(0xFFD64545);
  static const info = Color(0xFF0284C7);
  static const clear = Colors.transparent;
  static const scrim = Colors.black;
  static const darkBackground = Color(0xFF18130F);
  static const darkSurface = Color(0xFF251E19);
  static const darkCard = Color(0xFF302721);
  static const darkBorder = Color(0xFF4A3E35);
  static const darkTextSecondary = Color(0xFFD4C5BA);
  static const navDark = Color(0xFF24252A);
  static const heroLight = Color(0xFFFFC98D);
  static const heroMuted = Color(0xFFF3B676);
  static const darkOrange = Color(0xFF8A3300);

  static const promoOrange = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [primary, Color(0xFFE8590C)],
  );
  static const promoGreen = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF16694A), Color(0xFF0C3F2B)],
  );

  // Compatibility names used throughout existing screens. New code should use
  // semantic names above; keeping aliases preserves the existing dark mode.
  static const spiceOrange = primary;
  static const spiceOrangeDark = primaryDeep;
  static const goldenAmber = gold;
  static const warmBone = cream;
  static const surfaceWhite = surface;
  static const deepCharcoal = ink;
  static const midnightCard = darkCard;
  static const coastalEmerald = spiceGreen;
  static const editorialGray = inkMuted;
  static const mutedSlate = darkTextSecondary;
  static const softBorder = outline;
  static const dangerRed = danger;
  static const primaryDark = primaryDeep;
  static const primaryLight = gold;
  static const espresso = ember;
  static const error = danger;
  static const lightBackground = cream;
  static const lightBorder = outline;
  static const lightTextSecondary = inkMuted;

  static Color fromHex(String hex, {Color fallback = primary}) {
    final cleaned = hex.replaceAll('#', '').trim();
    if (cleaned.length == 6) {
      final parsed = int.tryParse('FF$cleaned', radix: 16);
      if (parsed != null) return Color(parsed);
    }
    return fallback;
  }
}
