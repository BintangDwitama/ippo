import 'package:flutter/widgets.dart';

/// Spacing used across screens.
abstract final class Gaps {
  static const double page = 16;

  /// Padding for a scrolling page: the usual margin, plus the space the
  /// system's navigation bar covers at the bottom, so the last item can
  /// be scrolled clear of it.
  static EdgeInsets pagePadding(BuildContext context) {
    return EdgeInsets.fromLTRB(
      page,
      page,
      page,
      page + MediaQuery.paddingOf(context).bottom,
    );
  }
  static const SizedBox small = SizedBox(height: 8, width: 8);
  static const SizedBox medium = SizedBox(height: 16, width: 16);
  static const SizedBox large = SizedBox(height: 32, width: 32);
}
