import 'package:flutter_test/flutter_test.dart';
import 'package:ippo/domain/models/review_card.dart';
import 'package:ippo/ui/lesson/lesson_ui_state.dart';
import 'package:ippo/ui/lesson/lesson_view_model.dart';

import '../support/builders.dart';
import '../support/fake_dependencies.dart';

void main() {
  final now = DateTime(2026, 1, 10, 9);

  Future<LessonViewModel> create(FakeDependencies deps) async {
    final viewModel = LessonViewModel(deps.app);
    addTearDown(viewModel.dispose);
    await pumpEventQueue();
    return viewModel;
  }

  FakeDependencies withLesson() => FakeDependencies(
        items: kanaItems(hiraganaCount: 46),
        goal: goal(createdAt: now),
        now: now,
      );

  /// Steps through the presentation of every kana to reach the quiz.
  void skipToQuiz(LessonViewModel viewModel) {
    while (viewModel.uiState is LessonPresenting) {
      viewModel.showNext();
    }
  }

  /// Answers every remaining quiz question correctly.
  Future<void> finishQuiz(LessonViewModel viewModel) async {
    while (viewModel.uiState is LessonQuiz) {
      final state = viewModel.uiState as LessonQuiz;
      await viewModel.answer(state.item);
    }
  }

  test('is unavailable when today\'s quota is used up', () async {
    final viewModel = await create(
      FakeDependencies(
        items: kanaItems(hiraganaCount: 46, introduced: 5, introducedAt: now),
        goal: goal(createdAt: now),
        now: now,
      ),
    );

    expect(viewModel.uiState, isA<LessonUnavailable>());
  });

  test('presents the first kana with its mnemonic and plays its sound',
      () async {
    final deps = withLesson();
    final viewModel = await create(deps);

    final state = viewModel.uiState as LessonPresenting;
    expect(state.item.kana.character, 'あ');
    expect(state.mnemonic.text, isNotEmpty);
    expect(state.index, 0);
    expect(state.total, 5);
    expect(deps.speech.spoken, ['あ']);
  });

  test('replaying the sound speaks the kana again', () async {
    final deps = withLesson();
    final viewModel = await create(deps);

    viewModel.replaySound();

    expect(deps.speech.spoken, ['あ', 'あ']);
  });

  test('presents each kana in order, then starts the quiz', () async {
    final deps = withLesson();
    final viewModel = await create(deps);
    final shown = <String>[];

    while (viewModel.uiState is LessonPresenting) {
      shown.add((viewModel.uiState as LessonPresenting).item.kana.character);
      viewModel.showNext();
    }

    expect(shown, ['あ', 'い', 'う', 'え', 'お']);
    expect(deps.speech.spoken, shown);
    final quiz = viewModel.uiState as LessonQuiz;
    expect(quiz.options, hasLength(4));
    expect(quiz.options, contains(quiz.item));
    expect(quiz.answered, 0);
    expect(quiz.total, 5);
  });

  test('answering everything correctly completes the lesson', () async {
    final deps = withLesson();
    final viewModel = await create(deps);
    skipToQuiz(viewModel);

    await finishQuiz(viewModel);

    final state = viewModel.uiState as LessonComplete;
    expect(state.items, hasLength(5));
    final items = await deps.items.getItems();
    expect(items.where((i) => i.isIntroduced), hasLength(5));
    final cards = await deps.cards.getCards();
    expect(cards, hasLength(10));
    expect(
      cards.map((c) => c.promptType).toSet(),
      {PromptType.charToSoundChoice, PromptType.soundToCharChoice},
    );
  });

  test('a wrong answer shows the correct kana and asks it again later',
      () async {
    final deps = withLesson();
    final viewModel = await create(deps);
    skipToQuiz(viewModel);
    final quiz = viewModel.uiState as LessonQuiz;
    final missed = quiz.item;
    final wrong = quiz.options.firstWhere((o) => o.id != missed.id);
    deps.speech.spoken.clear();

    await viewModel.answer(wrong);

    final feedback = viewModel.uiState as LessonFeedback;
    expect(feedback.item, missed);
    expect(feedback.chosen, wrong);
    expect(feedback.mnemonic.text, isNotEmpty);
    expect(deps.speech.spoken, [missed.kana.character]);

    viewModel.continueAfterFeedback();
    final asked = <int>[];
    while (viewModel.uiState is LessonQuiz) {
      final state = viewModel.uiState as LessonQuiz;
      asked.add(state.item.id);
      await viewModel.answer(state.item);
    }

    expect(asked, hasLength(5));
    expect(asked.last, missed.id);
    expect(viewModel.uiState, isA<LessonComplete>());
  });

  test('leaving before the end introduces nothing', () async {
    final deps = withLesson();
    // Disposed by the test itself, so not registered for tear-down.
    final viewModel = LessonViewModel(deps.app);
    await pumpEventQueue();
    skipToQuiz(viewModel);
    final quiz = viewModel.uiState as LessonQuiz;
    await viewModel.answer(quiz.item);

    viewModel.dispose();

    expect((await deps.items.getItems()).any((i) => i.isIntroduced), isFalse);
    expect(await deps.cards.getCards(), isEmpty);
    expect(deps.speech.stopCount, 1);
  });
}
