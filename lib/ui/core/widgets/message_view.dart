import 'package:flutter/material.dart';
import 'package:ippo/ui/core/spacing.dart';

/// A centred message with an optional action, for empty and end states.
class MessageView extends StatelessWidget {
  const MessageView({
    super.key,
    required this.icon,
    required this.title,
    this.detail,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? detail;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: theme.colorScheme.primary),
            Gaps.medium,
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            if (detail != null) ...[
              Gaps.small,
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (actionLabel != null) ...[
              Gaps.large,
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
