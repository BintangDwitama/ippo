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
    final isListening = state.promptType == PromptType.soundToCharChoice;
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
                        },
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Gaps.small,
                      if (isListening)
                        AudioButton(
                          onPressed: viewModel.replaySound,
                          large: true,
                        )
                      else
                        KanaText(state.item.kana.character, size: 160),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Gaps.medium,
          if (state.promptType.isTyped)
            _TypedAnswer(onSubmitted: viewModel.answerTyped)
          else
            ChoiceGrid(
              isKana: isListening,
              labels: [
                for (final option in state.options)
                  isListening ? option.kana.character : option.kana.romaji,
              ],
              onSelected: (index) =>
                  viewModel.answerChoice(state.options[index]),
            ),
        ],
      ),
    );
  }
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
    final theme = Theme.of(context);
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
                    detail: 'You answered "${state.givenAnswer}". '
                        'The answer is ${state.item.kana.character} '
                        '(${state.item.kana.romaji}).',
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
