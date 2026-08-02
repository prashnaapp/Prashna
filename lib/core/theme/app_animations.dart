import 'package:flutter/animation.dart';

abstract final class AppAnimations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration navigation = Duration(milliseconds: 250);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);

  static const curveStandard = Curves.easeOutCubic;
  static const curveEmphasized = Curves.easeInOutCubic;
  static const curveBounce = Curves.easeOutBack;
}
