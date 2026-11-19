import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Applies the stronger of the OS preference and the in-app reading size, then
/// enforces a readable font floor. Large text remains proportional so hierarchy
/// is preserved; tiny labels are lifted instead of multiplying an illegible 9dp.
@immutable
final class ReadableTextScaler extends TextScaler {
  const ReadableTextScaler({
    required this.systemScaler,
    required this.userScaleFactor,
    required this.minimumFontSize,
    required this.maxScaleFactor,
  });

  final TextScaler systemScaler;
  final double userScaleFactor;
  final double minimumFontSize;
  final double maxScaleFactor;

  @override
  double scale(double fontSize) {
    assert(fontSize >= 0);
    assert(fontSize.isFinite);

    final systemScaled = systemScaler.scale(fontSize);
    final preferredScaled = fontSize * userScaleFactor;
    final combined = math.max(systemScaled, preferredScaled);
    final capped = math.min(combined, fontSize * maxScaleFactor);

    if (fontSize <= 0) return combined;
    return math.max(capped, minimumFontSize * userScaleFactor);
  }

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => math.min(
        math.max(systemScaler.scale(20) / 20, userScaleFactor),
        maxScaleFactor,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReadableTextScaler &&
          other.systemScaler == systemScaler &&
          other.userScaleFactor == userScaleFactor &&
          other.minimumFontSize == minimumFontSize &&
          other.maxScaleFactor == maxScaleFactor;

  @override
  int get hashCode => Object.hash(
        systemScaler,
        userScaleFactor,
        minimumFontSize,
        maxScaleFactor,
      );

  @override
  String toString() =>
      'ReadableTextScaler(system: $systemScaler, user: $userScaleFactor, '
      'floor: $minimumFontSize, max: $maxScaleFactor)';
}
