import 'package:flutter/material.dart';

abstract final class AppSpace {
  static const double v5 = 5;
  static const double v38 = 38;
  static const double v42 = 42;
  static const double v148 = 148;
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

  static const double xxs = 2, xs = 4, sm = 8, md = 12, lg = 16, xl = 24, xxl = 32, huge = 48;
  static const double screenH = 20, navClearance = 112, navHeight = 72, navMaxWidth = 500;
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
    BoxShadow(color: Color(0x142B1B12), blurRadius: 24, offset: Offset(0, 8)),
  ];
  static const lifted = <BoxShadow>[
    BoxShadow(color: Color(0x242B1B12), blurRadius: 36, offset: Offset(0, 16)),
  ];
}

abstract final class AppMotion {
  static const fast = Duration(milliseconds: 150);
  static const base = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 480);
  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve spring = Curves.easeOutBack;
}

extension NavClearance on BuildContext {
  double get navClearance => AppSpace.navClearance + MediaQuery.paddingOf(this).bottom;
}

/// Shared card metrics so real widgets and their skeletons stay in sync
/// with zero visual drift. All values come from AppRadius / AppSpace tokens.
abstract final class PromoCardMetrics {
  static const double width = 285;
  static const double padding = AppSpace.lg;
  static const double borderRadius = AppRadius.v22;
}

abstract final class DiscoveryCardMetrics {
  static const double padding = AppSpace.lg;
  static const double borderRadius = AppRadius.md;
}

abstract final class DishCardMetrics {
  static const double cardHeight = 270;
  static const double cardMaxWidth = 230;
  static const double imageSize = 112;
  static const double gap = AppSpace.v14;
  static const double padding = AppSpace.md;
}
