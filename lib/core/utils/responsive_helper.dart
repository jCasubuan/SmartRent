import 'package:flutter/material.dart';

/// Responsive scaling utility for SmartRent.
///
/// Design baseline: 375dp width (standard iPhone SE / mid-range Android).
/// - Screens wider than 375dp: sizes stay the same (no upscaling).
/// - Screens narrower than 375dp: sizes scale down proportionally.
///
/// Usage:
/// ```dart
/// final r = Responsive(context);
/// Text('Hello', style: TextStyle(fontSize: r.sp(14)));
/// Padding(padding: EdgeInsets.all(r.s(16)));
/// SizedBox(width: r.s(100));
/// ```
///
/// Methods:
/// - `s(value)` — scales sizes (padding, margins, widths, heights, icon sizes)
/// - `sp(value)` — scales font sizes (same logic, separate for clarity)
/// - `w` — screen width in dp
/// - `h` — screen height in dp
class Responsive {
  final BuildContext context;
  late final double _scaleFactor;
  late final double w;
  late final double h;

  /// Design baseline width in dp.
  static const double _baseWidth = 375.0;

  Responsive(this.context) {
    final size = MediaQuery.sizeOf(context);
    w = size.width;
    h = size.height;
    // Only scale down, never up. Clamp at 1.0 max.
    _scaleFactor = (w / _baseWidth).clamp(0.75, 1.0);
  }

  /// Scale a size value (padding, margin, width, height, icon size).
  double s(double value) => value * _scaleFactor;

  /// Scale a font size value.
  double sp(double value) => value * _scaleFactor;
}
