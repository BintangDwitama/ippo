import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ippo/domain/models/goal.dart';
import 'package:ippo/domain/use_cases/get_goal_progress.dart';
import 'package:ippo/routing/routes.dart';
import 'package:ippo/ui/core/app_theme.dart';
import 'package:ippo/ui/core/widgets.dart';
import 'package:ippo/ui/home/home_ui_state.dart';
import 'package:ippo/ui/home/home_view_model.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// Opens [route] and refreshes the home screen when the learner returns.
  Future<void> _open(BuildContext context, String route) async {
    final viewModel = context.read<HomeViewModel>();
    await context.push(route);
    await viewModel.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();
    final state = viewModel.uiState;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ippo'),
        actions: [
          IconButton(
            tooltip: 'Kana',
            icon: const Icon(Icons.grid_view),
            onPressed: () => _open(context, Routes.kanaGrid),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _open(context, Routes.settings),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(Gaps.page),
              children: [
                if (state.showVoiceNotice) ...[
                  _VoiceNotice(onDismiss: viewModel.dismissVoiceNotice),
                  Gaps.medium,
                ],
                if (state.needsGoalSetup)
                  _GoalSetupCard(
                    onAccept: viewModel.acceptPresetGoal,
                    onAdjust: () => _open(context, Routes.goal),
                  )
                else
                  _GoalCard(
                    goal: state.goal!,
                    progress: state.progress!,
                    streak: state.streak,
                    onTap: () => _open(context, Routes.goal),
                  ),
                Gaps.medium,
                _ReviewCard(
                  state: state,
                  onStart: () => _open(context, Routes.review),
                ),
                Gaps.medium,
                _LessonCard(
                  lessonSize: state.lessonSize,
                  onStart: () => _open(context, Routes.lesson),
                ),
              ],
            ),
    );
  }
}

class _VoiceNotice extends StatelessWidget {
  const _VoiceNotice({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No Japanese voice found',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: scheme.onErrorContainer),
            ),
            Gaps.small,
            Text(
              'To hear the kana, install Japanese in your phone\'s '
              'text-to-speech settings (Settings > Accessibility > '
              'Text-to-speech > Install voice data). Lessons and reading '
              'reviews work without it; listening reviews are paused.',
              style: TextStyle(color: scheme.onErrorContainer),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onDismiss,
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalSetupCard extends StatelessWidget {
  const _GoalSetupCard({required this.onAccept, required this.onAdjust});

  final VoidCallback onAccept;
  final VoidCallback onAdjust;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Set your first goal', style: theme.textTheme.titleLarge),
            Gaps.small,
            Text(
              'Suggested: read all 46 hiragana with 90% accuracy within '
              '14 days. That is about five new kana a day.',
              style: theme.textTheme.bodyLarge,
            ),
            Gaps.medium,
            FilledButton(
              onPressed: onAccept,
              child: const Text('Start with this goal'),
            ),
            Gaps.small,
            Center(
              child: TextButton(
                onPressed: onAdjust,
                child: const Text('Adjust the goal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.progress,
    required this.streak,
    required this.onTap,
  });

  final Goal goal;
  final GoalProgress progress;
  final int streak;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accuracy = progress.accuracy;
    final headline = switch (progress.status) {
      GoalStatus.achieved => 'Goal achieved',
      GoalStatus.missed => 'Goal deadline passed',
      GoalStatus.active => progress.daysRemaining == 0
          ? 'Last day of your goal'
          : '${progress.daysRemaining} days left',
    };
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(headline, style: theme.textTheme.titleLarge),
                  ),
                  Icon(
                    Icons.local_fire_department,
                    color: streak > 0
                        ? theme.colorScheme.tertiary
                        : theme.colorScheme.outline,
                  ),
                  Text(' $streak', style: theme.textTheme.titleMedium),
                ],
              ),
              Gaps.medium,
              LinearProgressIndicator(
                value: progress.totalCount == 0
                    ? 0
                    : progress.introducedCount / progress.totalCount,
                minHeight: 10,
                borderRadius: BorderRadius.circular(5),
              ),
              Gaps.small,
              Text(
                '${progress.introducedCount} of ${progress.totalCount} '
                'kana introduced',
              ),
              Text(
                accuracy == null
                    ? 'Accuracy: no reviews in the last 7 days '
                        '(target ${(goal.targetAccuracy * 100).round()}%)'
                    : 'Accuracy: ${(accuracy * 100).round()}% '
                        '(target ${(goal.targetAccuracy * 100).round()}%)',
              ),
              if (progress.status != GoalStatus.active) ...[
                Gaps.small,
                Text(
                  progress.status == GoalStatus.achieved
                      ? 'Tap to set your next goal.'
                      : 'Tap to extend it or set a new one.',
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.state, required this.onStart});

  final HomeUiState state;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nextDue = state.nextDue;
    final String detail;
    if (state.dueCount > 0) {
      detail = state.dueCount == 1
          ? '1 card is due'
          : '${state.dueCount} cards are due';
    } else if (state.isReviewCapReached) {
      detail = 'You have reached today\'s review limit. '
          'The rest will wait for tomorrow.';
    } else if (nextDue != null) {
      detail =
          'Nothing due. Next card ${formatTimeUntil(nextDue, DateTime.now())}.';
    } else {
      detail = 'Nothing to review yet. Take a lesson to get started.';
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Review', style: theme.textTheme.titleLarge),
            Gaps.small,
            Text(detail, style: theme.textTheme.bodyLarge),
            Gaps.medium,
            FilledButton(
              onPressed: state.dueCount > 0 ? onStart : null,
              child: const Text('Start review'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({required this.lessonSize, required this.onStart});

  final int lessonSize;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lesson', style: theme.textTheme.titleLarge),
            Gaps.small,
            Text(
              lessonSize > 0
                  ? 'Learn $lessonSize new kana'
                  : 'No new kana for today. Come back tomorrow.',
              style: theme.textTheme.bodyLarge,
            ),
            Gaps.medium,
            FilledButton.tonal(
              onPressed: lessonSize > 0 ? onStart : null,
              child: const Text('Start lesson'),
            ),
          ],
        ),
      ),
    );
  }
}
