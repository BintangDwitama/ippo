import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ippo/ui/core/spacing.dart';
import 'package:ippo/ui/core/widgets/widgets.dart';
import 'package:ippo/ui/word_lesson/word_lesson_ui_state.dart';
import 'package:ippo/ui/word_lesson/word_lesson_view_model.dart';
import 'package:provider/provider.dart';

class WordLessonScreen extends StatelessWidget {
  const WordLessonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<WordLessonViewModel>();
    final state = viewModel.uiState;

    return Scaffold(
      appBar: switch (state) {
        WordLessonPresenting() => sessionAppBar(
            context,
            title: 'Word lesson',
            progress: state.index / state.total,
          ),
        WordLessonCheck() => sessionAppBar(
            context,
            title: 'Word check',
            progress: state.answered / state.total,
            count: '${state.answered} / ${state.total}',
          ),
        _ => sessionAppBar(context, title: 'Word lesson'),
      },
      body: SafeArea(
        child: switch (state) {
          WordLessonLoading() =>
            const Center(child: CircularProgressIndicator()),
          WordLessonUnavailable() => MessageView(
              icon: Icons.event_available,
              title: 'No new words for today',
              detail: 'New words open up as you learn more kana. '
                  'Come back after your next kana lesson, or tomorrow.',
              actionLabel: 'Back',
              onAction: () => context.pop(),
            ),
          WordLessonPresenting() =>
            _Presenting(state: state, viewModel: viewModel),
          WordLessonCheck() => _Check(state: state, viewModel: viewModel),
          WordLessonFeedback() =>
            _Feedback(state: state, viewModel: viewModel),
          WordLessonComplete() => MessageView(
              icon: Icons.celebration_outlined,
              title: 'Lesson complete',
              detail: 'You learned '
                  '${state.items.map((i) => i.word.reading).join(', ')}. '
                  '${state.items.length == 1 ? 'It is' : 'They are'} now '
                  'in your reviews.',
              actionLabel: 'Done',
              onAction: () => context.pop(),
            ),
        },
      ),
    );
  }
}

class _Presenting extends StatelessWidget {
  const _Presenting({required this.state, required this.viewModel});

  final WordLessonPresenting state;
  final WordLessonViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(Gaps.page),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Text(
                    'New word ${state.index + 1} of ${state.total}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Gaps.large,
                  WordDetail(
                    word: state.item.word,
                    onPlay: viewModel.replaySound,
                    voiceAvailable: state.voiceAvailable,
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              if (!state.isFirst) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: viewModel.showPrevious,
                    child: const Text('Back'),
                  ),
                ),
                Gaps.medium,
              ],
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: viewModel.showNext,
                  child: Text(state.isLast ? 'Start the check' : 'Next'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Check extends StatelessWidget {
  const _Check({required this.state, required this.viewModel});

  final WordLessonCheck state;
  final WordLessonViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(Gaps.page),
      child: Column(
        children: [
          Expanded(
            child: IppoCard(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'What does this mean?',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Gaps.small,
                      WordText(state.item.word, size: 72),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Gaps.medium,
          ChoiceList(
            children: [
              for (final option in state.options)
                MeaningChoice(option.word.meaningText),
            ],
            onSelected: (index) => viewModel.answer(state.options[index]),
          ),
        ],
      ),
    );
  }
}

class _Feedback extends StatelessWidget {
  const _Feedback({required this.state, required this.viewModel});

  final WordLessonFeedback state;
  final WordLessonViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Gaps.page),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  FeedbackBanner(
                    isCorrect: false,
                    label: 'Not quite',
                    detail: 'You chose "${state.chosen.word.meaningText}".',
                  ),
                  Gaps.large,
                  WordDetail(
                    word: state.item.word,
                    onPlay: viewModel.replaySound,
                    voiceAvailable: state.voiceAvailable,
                  ),
                ],
              ),
            ),
          ),
          FilledButton(
            onPressed: viewModel.continueAfterFeedback,
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}
