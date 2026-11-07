import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Signature Swahili Gastronomy Palette
  static const Color spiceOrange = Color(0xFFF6821F);
  static const Color spiceOrangeDark = Color(0xFFD96B0E);
  static const Color goldenAmber = Color(0xFFFBAD41);
  static const Color warmBone = Color(0xFFFBFBFA);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color deepCharcoal = Color(0xFF181C2E);
  static const Color midnightCard = Color(0xFF1E1E26);
  static const Color coastalEmerald = Color(0xFF15803D);
  static const Color editorialGray = Color(0xFF787774);
  static const Color mutedSlate = Color(0xFF9CA3AF);
  static const Color softBorder = Color(0xFFEAEAEA);
  static const Color dangerRed = Color(0xFFEF4444);

  // Semantic UI Tokens
  static const Color primary = spiceOrange;
  static const Color primaryDark = spiceOrangeDark;
  static const Color primaryLight = goldenAmber;
  static const Color espresso = Color(0xFF28170A);
  static const Color success = coastalEmerald;
  static const Color error = dangerRed;
  static const Color info = Color(0xFF0284C7);

  // Light & Dark Theme Surfaces
  static const Color lightBackground = warmBone;
  static const Color lightBorder = softBorder;
  static const Color lightTextSecondary = editorialGray;

  static const Color darkBackground = Color(0xFF11131A);
  static const Color darkSurface = Color(0xFF1A1D27);
  static const Color darkCard = Color(0xFF202431);
  static const Color darkBorder = Color(0xFF2B3040);
  static const Color darkTextSecondary = mutedSlate;

  static Color fromHex(String hex, {Color fallback = spiceOrange}) {
    final cleaned = hex.replaceAll('#', '').trim();
    if (cleaned.length == 6) {
      final parsed = int.tryParse('FF$cleaned', radix: 16);
      if (parsed != null) return Color(parsed);
    }
    return fallback;
  }
}
