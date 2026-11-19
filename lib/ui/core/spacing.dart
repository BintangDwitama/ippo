import 'package:flutter/widgets.dart';

/// Spacing used across screens.
abstract final class Gaps {
  static const double page = 16;
  static const SizedBox small = SizedBox(height: 8, width: 8);
  static const SizedBox medium = SizedBox(height: 16, width: 16);
  static const SizedBox large = SizedBox(height: 32, width: 32);
}
