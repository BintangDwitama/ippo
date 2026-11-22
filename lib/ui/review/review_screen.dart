import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ippo/domain/models/review_card.dart';
import 'package:ippo/ui/core/spacing.dart';
import 'package:ippo/ui/core/widgets/widgets.dart';
import 'package:ippo/ui/review/review_ui_state.dart';
import 'package:ippo/ui/review/review_view_model.dart';
import 'package:provider/provider.dart';

class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ReviewViewModel>();
    final state = viewModel.uiState;

    return Scaffold(
      appBar: state is ReviewQuestion
          ? sessionAppBar(
              context,
              title: 'Review',
              progress: state.reviewed / state.total,
              count: '${state.reviewed} / ${state.total}',
            )
          : sessionAppBar(context, title: 'Review'),
      body: SafeArea(
        child: switch (state) {
          ReviewLoading() => const Center(child: CircularProgressIndicator()),
          ReviewEmpty() => MessageView(
              icon: Icons.check_circle_outline,
              title: state.isCapReached
                  ? 'That is enough for today'
                  : 'Nothing to review',
              detail: state.isCapReached
                  ? 'You have reached today\'s review limit. '
                      'The rest will wait for tomorrow.'
                  : state.nextDue == null
                      ? 'Take a lesson to get your first cards.'
                      : 'Your next card is due '
                          '${formatTimeUntil(state.nextDue!, DateTime.now())}.',
              actionLabel: 'Back',
              onAction: () => context.pop(),
            ),
          ReviewQuestion() => _Question(
              // A new key resets the text field for each question.
              key: ValueKey((state.item.id, state.promptType, state.reviewed)),
              state: state,
              viewModel: viewModel,
            ),
          ReviewFeedback() => _Feedback(state: state, viewModel: viewModel),
          ReviewSummary() => MessageView(
              icon: Icons.emoji_events_outlined,
              title: 'Session complete',
              detail: '${state.reviewed} '
                  '${state.reviewed == 1 ? 'card' : 'cards'} reviewed, '
                  '${(state.accuracy * 100).round()}% correct at the '
                  'first attempt.',
              actionLabel: 'Done',
              onAction: () => context.pop(),
            ),
        },
      ),
    );
  }
}

class _Question extends StatelessWidget {
  const _Question({super.key, required this.state, required this.viewModel});

  final ReviewQuestion state;
  final ReviewViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = state.item;
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
                      if (state.isRepeat) ...[
                        Chip(
                          label: const Text('Once more'),
                          backgroundColor: theme.colorScheme.tertiaryContainer,
                          labelStyle: TextStyle(
                            color: theme.colorScheme.onTertiaryContainer,
                          ),
                        ),
                        Gaps.small,
                      ],
                      Text(
                        switch (state.promptType) {
                          PromptType.charToSoundChoice => 'How is this read?',
                          PromptType.soundToCharChoice =>
                            'Which kana makes this sound?',
                          PromptType.charToSoundTyped => 'Type the reading',
                          PromptType.wordToMeaningChoice =>
                            'What does this mean?',
                          PromptType.meaningToWordChoice =>
                            'Which word means this?',
                        },
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Gaps.small,
                      switch (state.promptType) {
                        PromptType.soundToCharChoice => AudioButton(
                            onPressed: viewModel.replaySound,
                            large: true,
                          ),
                        PromptType.charToSoundChoice ||
                        PromptType.charToSoundTyped =>
                          KanaText(item.kana.character, size: 160),
                        PromptType.wordToMeaningChoice =>
                          WordText(item.word, size: 72),
                        PromptType.meaningToWordChoice => Text(
                            item.word.meaningText,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium,
                          ),
                      },
                    ],
                  ),
                ),
              ),
            ),
          ),
          Gaps.medium,
          switch (state.promptType) {
            PromptType.charToSoundTyped =>
              _TypedAnswer(onSubmitted: viewModel.answerTyped),
            PromptType.charToSoundChoice => ChoiceGrid(
                labels: [for (final o in state.options) o.kana.romaji],
                onSelected: _select,
              ),
            PromptType.soundToCharChoice => ChoiceGrid(
                isKana: true,
                labels: [for (final o in state.options) o.kana.character],
                onSelected: _select,
              ),
            PromptType.wordToMeaningChoice => ChoiceList(
                onSelected: _select,
                children: [
                  for (final o in state.options)
                    MeaningChoice(o.word.meaningText),
                ],
              ),
            PromptType.meaningToWordChoice => ChoiceList(
                onSelected: _select,
                children: [for (final o in state.options) WordLine(o.word)],
              ),
          },
        ],
      ),
    );
  }

  void _select(int index) =>
      unawaited(viewModel.answerChoice(state.options[index]));
}

class _TypedAnswer extends StatefulWidget {
  const _TypedAnswer({required this.onSubmitted});

  final ValueChanged<String> onSubmitted;

  @override
  State<_TypedAnswer> createState() => _TypedAnswerState();
}

class _TypedAnswerState extends State<_TypedAnswer> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _controller,
          autofocus: true,
          autocorrect: false,
          enableSuggestions: false,
          textAlign: TextAlign.center,
          textInputAction: TextInputAction.done,
          keyboardType: TextInputType.visiblePassword,
          style: const TextStyle(fontSize: 28),
          decoration: const InputDecoration(hintText: 'romaji'),
          onSubmitted: widget.onSubmitted,
        ),
        Gaps.medium,
        FilledButton(
          onPressed: () => widget.onSubmitted(_controller.text),
          child: const Text('Check'),
        ),
      ],
    );
  }
}

class _Feedback extends StatelessWidget {
  const _Feedback({required this.state, required this.viewModel});

  final ReviewFeedback state;
  final ReviewViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Gaps.page),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: state.item.isWord
                    ? _wordFeedback()
                    : _kanaFeedback(Theme.of(context)),
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

  List<Widget> _wordFeedback() {
    return [
      if (state.wasCorrect)
        const FeedbackBanner(isCorrect: true, label: 'Correct')
      else
        FeedbackBanner(
          isCorrect: false,
          label: 'Not quite',
          detail: 'You chose "${state.givenAnswer}".',
        ),
      Gaps.large,
      WordDetail(
        word: state.item.word,
        onPlay: viewModel.replaySound,
        voiceAvailable: state.voiceAvailable,
      ),
    ];
  }

  List<Widget> _kanaFeedback(ThemeData theme) {
    final kana = state.item.kana;
    final mnemonic = state.mnemonic;
    return [
      FeedbackBanner(
        isCorrect: false,
        label: 'Not quite',
        detail: 'You answered "${state.givenAnswer}". '
            'The answer is ${kana.character} (${kana.romaji}).',
      ),
      Gaps.medium,
      KanaText(kana.character, size: 140),
      Text(kana.romaji, style: theme.textTheme.displaySmall),
      Gaps.medium,
      AudioButton(onPressed: viewModel.replaySound),
      Gaps.large,
      if (mnemonic != null) MnemonicNote(mnemonic.text),
    ];
  }
}
