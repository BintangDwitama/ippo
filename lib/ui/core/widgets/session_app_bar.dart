import 'package:flutter/material.dart';
import 'package:ippo/ui/core/widgets/progress_meter.dart';

/// The app bar of a lesson or review: the screen's name, or, while
/// questions are being asked, how far the session has got.
AppBar sessionAppBar(
  BuildContext context, {
  required String title,
  double? progress,
  String? count,
}) {
  if (progress == null) return AppBar(title: Text(title));
  return AppBar(
    title: Semantics(
      label: count == null ? title : '$title, $count',
      child: Row(
        children: [
          Expanded(child: ProgressMeter(value: progress)),
          if (count != null) ...[
            const SizedBox(width: 12),
            ExcludeSemantics(
              child: Text(
                count,
                textScaler: TextScaler.noScaling,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
          const SizedBox(width: 8),
        ],
      ),
    ),
  );
}
