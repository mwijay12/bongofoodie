import 'package:flutter/material.dart';

abstract final class AppSpace {
  static const double xs = 4, sm = 8, md = 12, lg = 16, xl = 24, xxl = 32, huge = 48;
  static const double screenH = 20, navClearance = 112;
}

abstract final class AppRadius {
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
