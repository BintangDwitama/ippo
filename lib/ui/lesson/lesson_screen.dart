import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ippo/ui/core/app_theme.dart';
import 'package:ippo/ui/core/widgets.dart';
import 'package:ippo/ui/lesson/lesson_ui_state.dart';
import 'package:ippo/ui/lesson/lesson_view_model.dart';
import 'package:provider/provider.dart';

class LessonScreen extends StatelessWidget {
  const LessonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LessonViewModel>();
    final state = viewModel.uiState;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lesson'),
        bottom: switch (state) {
          LessonPresenting() => _progress(state.index / state.total),
          LessonQuiz() => _progress(state.answered / state.total),
          _ => null,
        },
      ),
      body: SafeArea(
        child: switch (state) {
          LessonLoading() => const Center(child: CircularProgressIndicator()),
          LessonUnavailable() => MessageView(
              icon: Icons.event_available,
              title: 'No new kana for today',
              detail: 'Review what you know and come back tomorrow.',
              actionLabel: 'Back',
              onAction: () => context.pop(),
            ),
          LessonPresenting() => _Presenting(state: state, viewModel: viewModel),
          LessonQuiz() => _Quiz(state: state, viewModel: viewModel),
          LessonFeedback() => _Feedback(state: state, viewModel: viewModel),
          LessonComplete() => MessageView(
              icon: Icons.celebration_outlined,
              title: 'Lesson complete',
              detail: 'You learned '
                  '${state.items.map((i) => i.kana.character).join(' ')}. '
                  'They are now in your reviews.',
              actionLabel: 'Done',
              onAction: () => context.pop(),
            ),
        },
      ),
    );
  }

  PreferredSizeWidget _progress(double value) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(4),
      child: LinearProgressIndicator(value: value),
    );
  }
}

class _Presenting extends StatelessWidget {
  const _Presenting({required this.state, required this.viewModel});

  final LessonPresenting state;
  final LessonViewModel viewModel;

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
                    'New kana ${state.index + 1} of ${state.total}',
                    style: theme.textTheme.labelLarge,
                  ),
                  Gaps.medium,
                  KanaText(state.item.kana.character, size: 160),
                  Text(
                    state.item.kana.romaji,
                    style: theme.textTheme.displaySmall,
                  ),
                  Gaps.medium,
                  AudioButton(onPressed: viewModel.replaySound),
                  Gaps.large,
                  MnemonicNote(state.mnemonic.text),
                ],
              ),
            ),
          ),
          FilledButton(
            onPressed: viewModel.showNext,
            child: Text(state.isLast ? 'Start the quiz' : 'Next'),
          ),
        ],
      ),
    );
  }
}

class _Quiz extends StatelessWidget {
  const _Quiz({required this.state, required this.viewModel});

  final LessonQuiz state;
  final LessonViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Gaps.page),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'How is this read?',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    KanaText(state.item.kana.character, size: 160),
                  ],
                ),
              ),
            ),
          ),
          ChoiceGrid(
            labels: [for (final option in state.options) option.kana.romaji],
            onSelected: (index) => viewModel.answer(state.options[index]),
          ),
        ],
      ),
    );
  }
}

class _Feedback extends StatelessWidget {
  const _Feedback({required this.state, required this.viewModel});

  final LessonFeedback state;
  final LessonViewModel viewModel;

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
                    'Not quite. You chose "${state.chosen.kana.romaji}".',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: theme.colorScheme.error),
                  ),
                  Gaps.medium,
                  KanaText(state.item.kana.character, size: 140),
                  Text(
                    state.item.kana.romaji,
                    style: theme.textTheme.displaySmall,
                  ),
                  Gaps.medium,
                  AudioButton(onPressed: viewModel.replaySound),
                  Gaps.large,
                  MnemonicNote(state.mnemonic.text),
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
