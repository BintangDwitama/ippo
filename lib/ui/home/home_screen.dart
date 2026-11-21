import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ippo/domain/models/goal.dart';
import 'package:ippo/domain/use_cases/get_goal_progress.dart';
import 'package:ippo/routing/routes.dart';
import 'package:ippo/ui/core/spacing.dart';
import 'package:ippo/ui/core/theme/ippo_tokens.dart';
import 'package:ippo/ui/core/widgets/widgets.dart';
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
        title: Semantics(
          label: 'Ippo',
          child: ExcludeSemantics(
            child: Text(
              '一歩',
              locale: const Locale('ja'),
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                fontFamily: context.tokens.kanaFontFamily,
                fontSize: 30,
              ),
            ),
          ),
        ),
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
          const SizedBox(width: 4),
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
                if (state.needsGoalSetup) ...[
                  _GoalSetupCard(
                    onAccept: viewModel.acceptPresetGoal,
                    onAdjust: () => _open(context, Routes.goal),
                  ),
                  Gaps.medium,
                ],
                _PrimaryActionCard(
                  state: state,
                  onStartReview: () => _open(context, Routes.review),
                  onStartLesson: () => _open(context, Routes.lesson),
                ),
                if (state.lessonSize > 0) ...[
                  Gaps.medium,
                  _NextLessonCard(
                    kana: state.nextLessonKana,
                    // The hero already carries the lesson button when the
                    // lesson is the primary action.
                    onStart: state.primaryAction == HomePrimaryAction.review
                        ? () => _open(context, Routes.lesson)
                        : null,
                  ),
                ],
                if (!state.needsGoalSetup) ...[
                  Gaps.medium,
                  _GoalSummary(
                    goal: state.goal!,
                    progress: state.progress!,
                    streak: state.streak,
                    onTap: () => _open(context, Routes.goal),
                  ),
                ],
              ],
            ),
    );
  }
}

/// The one thing to do next: review, learn, or rest.
class _PrimaryActionCard extends StatelessWidget {
  const _PrimaryActionCard({
    required this.state,
    required this.onStartReview,
    required this.onStartLesson,
  });

  final HomeUiState state;
  final VoidCallback onStartReview;
  final VoidCallback onStartLesson;

  static const _label = 'Today\'s step';

  @override
  Widget build(BuildContext context) {
    final nextDue = state.nextDue;
    final String waiting;
    if (state.isReviewCapReached) {
      waiting =
          'You have reached today\'s review limit. '
          'The rest will wait for tomorrow.';
    } else if (nextDue != null) {
      waiting =
          'Nothing to review now. '
          'Next card ${formatTimeUntil(nextDue, DateTime.now())}.';
    } else {
      waiting = 'Your first review cards come from a lesson.';
    }

    return switch (state.primaryAction) {
      HomePrimaryAction.review => HeroCard(
        label: _label,
        figure: '${state.dueCount}',
        title: state.dueCount == 1 ? 'card to review' : 'cards to review',
        actionLabel: 'Start review',
        onAction: onStartReview,
      ),
      HomePrimaryAction.lesson => HeroCard(
        label: _label,
        figure: '${state.lessonSize}',
        title: 'new kana to learn',
        detail: waiting,
        actionLabel: 'Start lesson',
        onAction: onStartLesson,
      ),
      HomePrimaryAction.rest => HeroCard(
        label: _label,
        title: state.isReviewCapReached
            ? 'That is enough for today'
            : 'All done for now',
        detail: state.isReviewCapReached || nextDue != null
            ? waiting
            : 'No new kana for today. Come back tomorrow.',
      ),
    };
  }
}

/// The kana the next lesson introduces.
class _NextLessonCard extends StatelessWidget {
  const _NextLessonCard({required this.kana, this.onStart});

  final List<String> kana;

  /// Null when the lesson is started from the primary action instead.
  final VoidCallback? onStart;

  /// Shorter lessons leave empty cells so tiles keep their usual size;
  /// a lesson of six uses six narrower ones.
  static const int _minColumns = 5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return IppoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            children: [
              Text('Next lesson', style: theme.textTheme.titleMedium),
              Text(
                '${kana.length} new kana',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Gaps.medium,
          Row(
            children: [
              for (var i = 0;
                  i < (kana.length > _minColumns ? kana.length : _minColumns);
                  i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: i < kana.length
                      ? KanaTile(
                          character: kana[i],
                          background: scheme.secondaryContainer,
                          foreground: scheme.onSecondaryContainer,
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
          if (onStart != null) ...[
            Gaps.medium,
            SecondaryButton(label: 'Start lesson', onPressed: onStart),
          ],
        ],
      ),
    );
  }
}

/// Goal progress and the streak, side by side.
class _GoalSummary extends StatelessWidget {
  const _GoalSummary({
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
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final accuracy = progress.accuracy;
    final target = (goal.targetAccuracy * 100).round();
    final headline = switch (progress.status) {
      GoalStatus.achieved => 'Goal achieved',
      GoalStatus.missed => 'Goal deadline passed',
      GoalStatus.active =>
        progress.daysRemaining == 0
            ? 'Last day of your goal'
            : '${progress.daysRemaining} days left',
    };
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: IppoCard(
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(headline, style: theme.textTheme.titleMedium),
                  Gaps.small,
                  ProgressMeter(
                    value: progress.totalCount == 0
                        ? 0
                        : progress.introducedCount / progress.totalCount,
                  ),
                  Gaps.small,
                  Text(
                    '${progress.introducedCount} of ${progress.totalCount} '
                    'kana introduced',
                    style: muted,
                  ),
                  Text(
                    accuracy == null
                        ? 'No reviews yet, target $target%'
                        : 'Accuracy ${(accuracy * 100).round()}%, '
                              'target $target%',
                    style: muted,
                  ),
                  if (progress.status != GoalStatus.active) ...[
                    Gaps.small,
                    Text(
                      progress.status == GoalStatus.achieved
                          ? 'Tap to set your next goal.'
                          : 'Tap to extend it or set a new one.',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Center(child: StreakBadge(days: streak)),
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
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    return IppoCard(
      color: tokens.wrong,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No Japanese voice found',
            style: textTheme.titleMedium?.copyWith(color: tokens.onWrong),
          ),
          Gaps.small,
          Text(
            'To hear the kana, install Japanese in your phone\'s '
            'text-to-speech settings (Settings > Accessibility > '
            'Text-to-speech > Install voice data). Lessons and reading '
            'reviews work without it; listening reviews are paused.',
            style: textTheme.bodyMedium?.copyWith(color: tokens.onWrong),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              style: TextButton.styleFrom(foregroundColor: tokens.onWrong),
              onPressed: onDismiss,
              child: const Text('Got it'),
            ),
          ),
        ],
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
    return IppoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Set your first goal', style: theme.textTheme.titleLarge),
          Gaps.small,
          Text(
            'Suggested: read all 46 hiragana with 90% accuracy within '
            '14 days. That is about five new kana a day.',
            style: theme.textTheme.bodyLarge,
          ),
          Gaps.medium,
          SecondaryButton(label: 'Start with this goal', onPressed: onAccept),
          Gaps.small,
          Center(
            child: TextButton(
              onPressed: onAdjust,
              child: const Text('Adjust the goal'),
            ),
          ),
        ],
      ),
    );
  }
}
