import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ippo/domain/models/goal.dart';
import 'package:ippo/domain/use_cases/save_goal.dart';
import 'package:ippo/ui/core/spacing.dart';
import 'package:ippo/ui/core/widgets/widgets.dart';
import 'package:ippo/ui/goal/goal_ui_state.dart';
import 'package:ippo/ui/goal/goal_view_model.dart';
import 'package:provider/provider.dart';

class GoalScreen extends StatelessWidget {
  const GoalScreen({super.key});

  /// The choices as the learner meets them: along the teaching path
  /// first, then the two that span it.
  static const List<GoalTargetSet> _targetsInPathOrder = [
    GoalTargetSet.hiragana,
    GoalTargetSet.hiraganaExtended,
    GoalTargetSet.katakana,
    GoalTargetSet.katakanaExtended,
    GoalTargetSet.both,
    GoalTargetSet.everything,
  ];

  Future<void> _save(BuildContext context) async {
    final viewModel = context.read<GoalViewModel>();
    await viewModel.save();
    if (viewModel.uiState.isSaved && context.mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GoalViewModel>();
    final state = viewModel.uiState;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Goal')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(Gaps.page),
              children: [
                if (state.progress != null) ...[
                  _StatusBanner(state: state),
                  Gaps.large,
                ],
                Text(
                  state.startsNewGoal ? 'New goal' : 'Edit goal',
                  style: theme.textTheme.titleLarge,
                ),
                Gaps.medium,
                Text('Which kana', style: theme.textTheme.titleMedium),
                Gaps.small,
                for (final target in _targetsInPathOrder)
                  _TargetOption(
                    target: target,
                    count: state.targetCounts[target] ?? 0,
                    isSelected: target == state.targetSet,
                    onSelected: () => viewModel.setTargetSet(target),
                  ),
                Gaps.large,
                Text(
                  'Accuracy to reach: ${state.accuracyPercent}%',
                  style: theme.textTheme.titleMedium,
                ),
                Slider(
                  value: state.accuracyPercent.toDouble(),
                  min: SaveGoal.minAccuracy * 100,
                  max: SaveGoal.maxAccuracy * 100,
                  divisions: 10,
                  label: '${state.accuracyPercent}%',
                  onChanged: (value) =>
                      viewModel.setAccuracyPercent(value.round()),
                ),
                Gaps.medium,
                Text(
                  state.startsNewGoal
                      ? 'Days from today'
                      : 'Days from when the goal was set',
                  style: theme.textTheme.titleMedium,
                ),
                Gaps.small,
                Row(
                  children: [
                    IconButton.filledTonal(
                      tooltip: 'Fewer days',
                      onPressed: () =>
                          viewModel.setDeadlineDays(state.deadlineDays - 1),
                      icon: const Icon(Icons.remove),
                    ),
                    Expanded(
                      child: Text(
                        '${state.deadlineDays}',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium,
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: 'More days',
                      onPressed: () =>
                          viewModel.setDeadlineDays(state.deadlineDays + 1),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                if (state.error != null) ...[
                  Gaps.medium,
                  Text(switch (state.error!) {
                    GoalValidationError.deadlineTooShort =>
                      'The goal needs at least one day.',
                    GoalValidationError.accuracyOutOfRange =>
                      'Accuracy must be between 50% and 100%.',
                  }, style: TextStyle(color: theme.colorScheme.error)),
                ],
                Gaps.large,
                PrimaryButton(
                  label: state.startsNewGoal
                      ? 'Start this goal'
                      : 'Save changes',
                  onPressed: () => _save(context),
                ),
              ],
            ),
    );
  }
}

/// One choice of which kana the goal covers; exactly one is selected.
class _TargetOption extends StatelessWidget {
  const _TargetOption({
    required this.target,
    required this.count,
    required this.isSelected,
    required this.onSelected,
  });

  final GoalTargetSet target;
  final int count;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title = switch (target) {
      GoalTargetSet.hiragana => 'Hiragana basics',
      GoalTargetSet.hiraganaExtended => 'Hiragana voiced and combination',
      GoalTargetSet.katakana => 'Katakana basics',
      GoalTargetSet.katakanaExtended => 'Katakana voiced and combination',
      GoalTargetSet.both => 'Both basic sets',
      GoalTargetSet.everything => 'All kana',
    };
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: isSelected,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          isSelected
              ? Icons.radio_button_checked
              : Icons.radio_button_unchecked,
          color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
        ),
        title: Text(title),
        subtitle: Text('$count kana'),
        onTap: onSelected,
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.state});

  final GoalUiState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = state.progress!;
    final accuracy = progress.accuracy;
    final title = switch (progress.status) {
      GoalStatus.achieved => 'Goal achieved. Well done!',
      GoalStatus.missed => 'The deadline has passed',
      GoalStatus.active => 'Goal in progress',
    };
    final hint = switch (progress.status) {
      GoalStatus.achieved => 'Set your next goal below.',
      GoalStatus.missed =>
        'Add more days below to extend it, or change the goal.',
      GoalStatus.active => '${progress.daysRemaining} days remaining.',
    };
    return IppoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleLarge),
          Gaps.medium,
          ProgressMeter(
            value: progress.totalCount == 0
                ? 0
                : progress.introducedCount / progress.totalCount,
          ),
          Gaps.small,
          Text(
            '${progress.introducedCount} of ${progress.totalCount} kana '
            'introduced',
          ),
          Text(
            accuracy == null
                ? 'No reviews in the last 7 days'
                : 'Accuracy over the last 7 days: '
                      '${(accuracy * 100).round()}%',
          ),
          Gaps.small,
          Text(
            hint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
