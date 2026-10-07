import 'package:flutter/animation.dart';

abstract final class AppMotion {
  static const instant = Duration(milliseconds: 120);
  static const fast = Duration(milliseconds: 180);
  static const normal = Duration(milliseconds: 260);
  static const slow = Duration(milliseconds: 420);

  static const easeOut = Curves.easeOutCubic;
  static const easeInOut = Curves.easeInOutCubic;

  /// Long, soft landing for things arriving on screen.
  static const settle = Curves.easeOutQuart;

  /// Fast start and long glide, for elements that travel across the screen.
  static const emphasized = Curves.easeInOutCubicEmphasized;
}
