import 'package:flutter/material.dart';

abstract final class AppSpace {
  static const double v5 = 5;
  static const double v38 = 38;
  static const double v42 = 42;
  static const double v52 = 52;
  static const double v55 = 55;
  static const double v56 = 56;
  static const double v65 = 65;
  static const double v76 = 76;
  static const double v80 = 80;
  static const double v92 = 92;
  static const double v118 = 118;
  static const double v132 = 132;
  static const double v148 = 148;
  static const double v190 = 190;
  static const double v220 = 220;

  static const double v0 = 0;
  static const double v2 = 2;
  static const double v3 = 3;
  static const double v4 = 4;
  static const double v6 = 6;
  static const double v7 = 7;
  static const double v8 = 8;
  static const double v10 = 10;
  static const double v12 = 12;
  static const double v14 = 14;
  static const double v16 = 16;
  static const double v18 = 18;
  static const double v20 = 20;
  static const double v22 = 22;
  static const double v24 = 24;
  static const double v26 = 26;
  static const double v30 = 30;
  static const double v32 = 32;
  static const double v40 = 40;
  static const double hairline = 1;

  static const double xxs = 2,
      xs = 4,
      sm = 8,
      md = 12,
      lg = 16,
      xl = 24,
      xxl = 32,
      huge = 48;
  static const double screenH = 20;
  static const double navHeight = 72;
  static const double navBottomInset = md;
  static const double navClearance = navHeight + lg;
  static const double navMaxWidth = 500;
}

abstract final class AppRadius {
  static const double v4 = 4;
  static const double v10 = 10;
  static const double v12 = 12;
  static const double v14 = 14;
  static const double v16 = 16;
  static const double v18 = 18;
  static const double v22 = 22;
  static const double v24 = 24;
  static const double v26 = 26;
  static const double v28 = 28;
  static const double v999 = 999;

  static const double sm = 12, md = 20, lg = 28, xl = 36, pill = 999;
}

abstract final class AppShadows {
  static const soft = <BoxShadow>[
    BoxShadow(
      color: Color(0x142B1B12),
      blurRadius: AppSpace.v24,
      offset: Offset(AppSpace.v0, AppSpace.v8),
    ),
  ];
  static const lifted = <BoxShadow>[
    BoxShadow(
      color: Color(0x242B1B12),
      blurRadius: AppSpace.v32 + AppSpace.v4,
      offset: Offset(AppSpace.v0, AppSpace.v16),
    ),
  ];
}

abstract final class AppMotion {
  static const fast = Duration(milliseconds: 150);
  static const base = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 480);
  static const float = Duration(milliseconds: 3200);
  static const staggerDelay = Duration(milliseconds: 120);
  static const addedLabel = Duration(milliseconds: 1200);
  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve spring = Curves.easeOutBack;
  static const Curve floatCurve = Curves.easeInOut;
  static const double staggerOffset = 18;
  static const double transitionScaleBegin = 0.98;
  static const double popScale = 1.18;
  static const double floatMidpoint = 0.5;
}

/// Shared shell clearance: nav height + safe area + AppSpace.lg.
extension NavClearance on BuildContext {
  double get navClearance =>
      AppSpace.navClearance + MediaQuery.paddingOf(this).bottom;
}

/// Shared card metrics so real widgets and their skeletons stay in sync
/// with zero visual drift. All values come from AppRadius / AppSpace tokens.
abstract final class PromoCardMetrics {
  /// Original 285x220 footprint kept: only the artwork grows, the card does not.
  static const double width = 285;
  static const double height = 220;
  static const double padding = AppSpace.v10;
  static const double borderRadius = AppRadius.v22;

  /// 1.47x the old 76dp slot (76 -> 112): food leads, card stays 285x220.
  static const double imageSize = 112;
  static const double imageRadius = AppRadius.v16;
  static const double imageGap = AppSpace.v6;

  /// Copy inside the carousel is clamped here; the card itself stays fixed.
  static const double maxTextScale = 1.3;

  /// Headroom for the clamped scale range only.
  static double heightFor(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final clamped = scale.clamp(1.0, maxTextScale);
    return height + (clamped - 1) * 80;
  }
}

abstract final class DiscoveryCardMetrics {
  static const double padding = AppSpace.lg;
  static const double borderRadius = AppRadius.md;
}

abstract final class DishCardMetrics {
  static const double cardHeight = 298;
  static const double cardMaxWidth = 230;
  static const double imageSize = 140;
  static const double gap = AppSpace.v14;
  static const double padding = AppSpace.md;
}

/// Detail-page metrics kept beside the other design tokens so the route,
/// hero, skeleton and sticky bar all agree on one geometry.
abstract final class DishDetailMetrics {
  static const double heroHeightFactor = 0.42;
  static const double heroMaxHeight = 380;
  static const double heroCircleSize = 260;
  static const double heroCircleAlignmentY = 0.08;
  static const double heroImageSize = 300;
  static const double floatDistance = 6;
  static const double contactShadowWidth = 160;
  static const double contactShadowHeight = 24;
  static const double contactShadowBlur = 24;
  static const double stickyBarHeight = 80;
  static const int quantityMin = 1;
  static const int quantityMax = 20;
  static const int staggerItems = 8;
  static const double sectionTop = AppSpace.v18;
  static const double sectionBottom = AppSpace.v10;
  static const double sectionGap = AppSpace.md;
  static const double spicePillHeight = AppSpace.v10;
  static const double addOnRowMinHeight = AppSpace.v56;
}

abstract final class MenuImageMetrics {
  static const double gridImage = 128;
  static const double listImage = AppSpace.v92;
  static const double gridRatio = 0.64;
  static const double cartImage = 68;
}

abstract final class OnboardingImageMetrics {
  static const double size = 280;
  static const double padding = AppSpace.v14;
  static const double activeIndicatorWidth = 28;
}

abstract final class CheckoutMetrics {
  static const undoDuration = Duration(seconds: 5);
}
