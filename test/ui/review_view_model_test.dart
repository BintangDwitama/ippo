import 'package:flutter_test/flutter_test.dart';
import 'package:ippo/domain/models/review_card.dart';
import 'package:ippo/ui/review/review_ui_state.dart';
import 'package:ippo/ui/review/review_view_model.dart';

import '../support/builders.dart';
import '../support/fake_dependencies.dart';

void main() {
  final now = DateTime(2026, 1, 10, 9);
  final due = now.toUtc();

  Future<ReviewViewModel> create(FakeDependencies deps) async {
    final viewModel = ReviewViewModel(deps.app);
    addTearDown(viewModel.dispose);
    await pumpEventQueue();
    return viewModel;
  }

  FakeDependencies withCards(
    List<ReviewCard> cards, {
    bool japaneseVoiceAvailable = true,
  }) {
    return FakeDependencies(
      items: kanaItems(hiraganaCount: 12, introduced: 12),
      cards: cards,
      now: now,
      japaneseVoiceAvailable: japaneseVoiceAvailable,
    );
  }

  test('is empty with the next due time when nothing is due', () async {
    final later = now.add(const Duration(hours: 5)).toUtc();
    final viewModel = await create(
      withCards([reviewCard(id: 1, itemId: 1, due: later)]),
    );

    final state = viewModel.uiState as ReviewEmpty;
    expect(state.nextDue, later);
    expect(state.isCapReached, isFalse);
  });

  test('is empty and says so when the daily cap is reached', () async {
    final deps = FakeDependencies(
      items: kanaItems(hiraganaCount: 12, introduced: 12),
      cards: [reviewCard(id: 1, itemId: 1, due: due)],
      reviews: [reviewRecord(id: 1, cardId: 1, reviewedAt: now)],
      now: now,
    );
    deps.settings.dailyReviewCap = 1;

    final viewModel = await create(deps);

    expect((viewModel.uiState as ReviewEmpty).isCapReached, isTrue);
  });

  test('asks a multiple-choice question with four options', () async {
    final viewModel = await create(
      withCards([reviewCard(id: 1, itemId: 6, due: due)]),
    );

    final state = viewModel.uiState as ReviewQuestion;
    expect(state.item.kana.character, 'か');
    expect(state.promptType, PromptType.charToSoundChoice);
    expect(state.options, hasLength(4));
    expect(
      state.options.where((o) => o.kana.romaji == 'ka'),
      hasLength(1),
    );
    expect(state.reviewed, 0);
    expect(state.total, 1);
    expect(state.isRepeat, isFalse);
  });

  test('a correct answer is saved and ends a one-card session', () async {
    final deps = withCards([reviewCard(id: 1, itemId: 6, due: due)]);
    final viewModel = await create(deps);
    final question = viewModel.uiState as ReviewQuestion;

    await viewModel.answerChoice(question.item);

    final summary = viewModel.uiState as ReviewSummary;
    expect(summary.reviewed, 1);
    expect(summary.accuracy, 1);
    final records = await deps.reviews.getReviews();
    expect(records.single.wasCorrect, isTrue);
    expect((await deps.cards.getCards()).single.isDueAt(now), isFalse);
  });

  test('a wrong answer shows feedback, then the card returns ungraded',
      () async {
    final deps = withCards([reviewCard(id: 1, itemId: 6, due: due)]);
    final viewModel = await create(deps);
    final question = viewModel.uiState as ReviewQuestion;
    final wrong = question.options.firstWhere((o) => o.id != question.item.id);

    await viewModel.answerChoice(wrong);

    final feedback = viewModel.uiState as ReviewFeedback;
    expect(feedback.item.kana.character, 'か');
    expect(feedback.givenAnswer, wrong.kana.romaji);
    expect(feedback.mnemonic.text, isNotEmpty);
    expect(deps.speech.spoken, ['か']);

    viewModel.continueAfterFeedback();
    final repeat = viewModel.uiState as ReviewQuestion;
    expect(repeat.isRepeat, isTrue);
    expect(repeat.item.id, question.item.id);

    await viewModel.answerChoice(repeat.item);

    final summary = viewModel.uiState as ReviewSummary;
    expect(summary.reviewed, 1);
    expect(summary.accuracy, 0);
    // Only the first attempt was graded and recorded.
    expect(await deps.reviews.getReviews(), hasLength(1));
    expect((await deps.cards.getCards()).single.lapses, 1);
  });

  test('typed answers accept alternative romanisations', () async {
    final deps = FakeDependencies(
      items: [
        kanaItem(
          id: 1,
          character: 'つ',
          romaji: 'tsu',
          alternatives: const ['tu'],
          introducedAt: now,
        ),
      ],
      cards: [
        reviewCard(
          id: 1,
          itemId: 1,
          promptType: PromptType.charToSoundTyped,
          due: due,
        ),
      ],
      now: now,
    );
    final viewModel = await create(deps);
    final question = viewModel.uiState as ReviewQuestion;
    expect(question.options, isEmpty);

    await viewModel.answerTyped(' TU ');

    expect(viewModel.uiState, isA<ReviewSummary>());
    expect((await deps.reviews.getReviews()).single.wasCorrect, isTrue);
  });

  test('a wrong typed answer shows what was typed', () async {
    final deps = withCards([
      reviewCard(
        id: 1,
        itemId: 6,
        promptType: PromptType.charToSoundTyped,
        due: due,
      ),
    ]);
    final viewModel = await create(deps);

    await viewModel.answerTyped('ki');

    expect((viewModel.uiState as ReviewFeedback).givenAnswer, 'ki');
  });

  test('an empty typed answer is ignored', () async {
    final deps = withCards([
      reviewCard(
        id: 1,
        itemId: 6,
        promptType: PromptType.charToSoundTyped,
        due: due,
      ),
    ]);
    final viewModel = await create(deps);

    await viewModel.answerTyped('   ');

    expect(viewModel.uiState, isA<ReviewQuestion>());
    expect(await deps.reviews.getReviews(), isEmpty);
  });

  test('a listening question plays the sound and offers characters',
      () async {
    final deps = withCards([
      reviewCard(
        id: 1,
        itemId: 6,
        promptType: PromptType.soundToCharChoice,
        due: due,
      ),
    ]);
    final viewModel = await create(deps);

    final question = viewModel.uiState as ReviewQuestion;
    expect(question.promptType, PromptType.soundToCharChoice);
    expect(deps.speech.spoken, ['か']);

    viewModel.replaySound();
    expect(deps.speech.spoken, ['か', 'か']);

    final wrong = question.options.firstWhere((o) => o.id != question.item.id);
    await viewModel.answerChoice(wrong);
    expect(
      (viewModel.uiState as ReviewFeedback).givenAnswer,
      wrong.kana.character,
    );
  });

  test('listening cards are skipped and stay due without a voice', () async {
    final deps = withCards(
      [
        reviewCard(id: 1, itemId: 6, due: due),
        reviewCard(
          id: 2,
          itemId: 7,
          promptType: PromptType.soundToCharChoice,
          due: due,
        ),
      ],
      japaneseVoiceAvailable: false,
    );
    final viewModel = await create(deps);

    final question = viewModel.uiState as ReviewQuestion;
    expect(question.total, 1);
    await viewModel.answerChoice(question.item);

    expect(viewModel.uiState, isA<ReviewSummary>());
    final listening = (await deps.cards.getCards()).firstWhere((c) => c.id == 2);
    expect(listening.isDueAt(now), isTrue);
    expect(listening.reps, 0);
  });

  test('answers given before leaving early are kept', () async {
    final deps = withCards([
      for (var i = 1; i <= 4; i++) reviewCard(id: i, itemId: i, due: due),
    ]);
    // Disposed by the test itself, so not registered for tear-down.
    final viewModel = ReviewViewModel(deps.app);
    await pumpEventQueue();

    for (var i = 0; i < 2; i++) {
      final question = viewModel.uiState as ReviewQuestion;
      await viewModel.answerChoice(question.item);
    }
    viewModel.dispose();

    expect(await deps.reviews.getReviews(), hasLength(2));
    final stillDue =
        (await deps.cards.getCards()).where((c) => c.isDueAt(now));
    expect(stillDue, hasLength(2));
  });

  test('the summary reports first-attempt accuracy over the session',
      () async {
    final deps = withCards([
      for (var i = 1; i <= 4; i++) reviewCard(id: i, itemId: i, due: due),
    ]);
    final viewModel = await create(deps);
    var missedOne = false;

    while (viewModel.uiState is! ReviewSummary) {
      final state = viewModel.uiState;
      if (state is ReviewFeedback) {
        viewModel.continueAfterFeedback();
      } else if (state is ReviewQuestion) {
        if (!missedOne) {
          missedOne = true;
          await viewModel.answerChoice(
            state.options.firstWhere((o) => o.id != state.item.id),
          );
        } else {
          await viewModel.answerChoice(state.item);
        }
      }
    }

    final summary = viewModel.uiState as ReviewSummary;
    expect(summary.reviewed, 4);
    expect(summary.accuracy, 0.75);
    expect(await deps.reviews.getReviews(), hasLength(4));
  });
}
