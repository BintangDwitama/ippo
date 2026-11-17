import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ippo/domain/models/goal.dart';
import 'package:ippo/domain/use_cases/save_goal.dart';
import 'package:ippo/ui/core/app_theme.dart';
import 'package:ippo/ui/goal/goal_ui_state.dart';
import 'package:ippo/ui/goal/goal_view_model.dart';
import 'package:provider/provider.dart';

class GoalScreen extends StatelessWidget {
  const GoalScreen({super.key});

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
                SegmentedButton<GoalTargetSet>(
                  segments: const [
                    ButtonSegment(
                      value: GoalTargetSet.hiragana,
                      label: Text('Hiragana'),
                    ),
                    ButtonSegment(
                      value: GoalTargetSet.katakana,
                      label: Text('Katakana'),
                    ),
                    ButtonSegment(
                      value: GoalTargetSet.both,
                      label: Text('Both'),
                    ),
                  ],
                  selected: {state.targetSet},
                  onSelectionChanged: (selection) =>
                      viewModel.setTargetSet(selection.first),
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
                  Text(
                    switch (state.error!) {
                      GoalValidationError.deadlineTooShort =>
                        'The goal needs at least one day.',
                      GoalValidationError.accuracyOutOfRange =>
                        'Accuracy must be between 50% and 100%.',
                    },
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
                Gaps.large,
                FilledButton(
                  onPressed: () => _save(context),
                  child: Text(
                    state.startsNewGoal ? 'Start this goal' : 'Save changes',
                  ),
                ),
              ],
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleLarge),
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
            Text(hint),
          ],
        ),
      ),
    );
  }
}
