import 'package:flutter_test/flutter_test.dart';
import 'package:ippo/domain/models/goal.dart';
import 'package:ippo/domain/models/review_card.dart';
import 'package:ippo/ui/home/home_view_model.dart';

import '../support/builders.dart';
import '../support/fake_dependencies.dart';

void main() {
  final now = DateTime(2026, 1, 10, 9);

  Future<HomeViewModel> create(FakeDependencies deps) async {
    final viewModel = HomeViewModel(deps.app);
    addTearDown(viewModel.dispose);
    await pumpEventQueue();
    return viewModel;
  }

  test('starts in the loading state', () {
    final viewModel = HomeViewModel(FakeDependencies().app);
    addTearDown(viewModel.dispose);

    expect(viewModel.uiState.isLoading, isTrue);
    expect(viewModel.uiState.needsGoalSetup, isFalse);
  });

  test('asks for a goal on first launch', () async {
    final viewModel =
        await create(FakeDependencies(items: kanaItems(hiraganaCount: 46)));

    expect(viewModel.uiState.isLoading, isFalse);
    expect(viewModel.uiState.needsGoalSetup, isTrue);
    expect(viewModel.uiState.progress, isNull);
  });

  test('accepting the preset creates the goal and offers a lesson', () async {
    final deps = FakeDependencies(items: kanaItems(hiraganaCount: 46));
    final viewModel = await create(deps);

    await viewModel.acceptPresetGoal();
    await pumpEventQueue();

    final state = viewModel.uiState;
    expect(state.needsGoalSetup, isFalse);
    expect(state.goal!.targetSet, GoalTargetSet.hiragana);
    expect(state.progress!.totalCount, 46);
    expect(state.progress!.introducedCount, 0);
    expect(state.progress!.daysRemaining, 14);
    expect(state.lessonSize, 5);
    expect(state.dueCount, 0);
  });

  test('counts due cards and updates when a card changes', () async {
    final deps = FakeDependencies(
      items: kanaItems(hiraganaCount: 12, introduced: 2),
      cards: [
        reviewCard(id: 1, itemId: 1, due: now.toUtc()),
        reviewCard(id: 2, itemId: 2, due: now.toUtc()),
      ],
      goal: goal(createdAt: now),
      now: now,
    );
    final viewModel = await create(deps);
    expect(viewModel.uiState.dueCount, 2);

    final card = (await deps.cards.getCards()).first;
    await deps.app.gradeAnswer(card: card, wasCorrect: true, now: now);
    await pumpEventQueue();

    expect(viewModel.uiState.dueCount, 1);
    expect(viewModel.uiState.streak, 1);
  });

  test('shows when the next card is due if nothing is due now', () async {
    final nextDue = now.add(const Duration(hours: 3)).toUtc();
    final viewModel = await create(
      FakeDependencies(
        items: kanaItems(hiraganaCount: 12, introduced: 1),
        cards: [reviewCard(id: 1, itemId: 1, due: nextDue)],
        goal: goal(createdAt: now),
        now: now,
      ),
    );

    expect(viewModel.uiState.dueCount, 0);
    expect(viewModel.uiState.nextDue, nextDue);
    expect(viewModel.uiState.isReviewCapReached, isFalse);
  });

  test('reports when the daily review cap has been reached', () async {
    final deps = FakeDependencies(
      items: kanaItems(hiraganaCount: 12, introduced: 2),
      cards: [
        reviewCard(id: 1, itemId: 1, due: now.toUtc()),
        reviewCard(id: 2, itemId: 2, due: now.toUtc()),
      ],
      reviews: [reviewRecord(id: 1, cardId: 1, reviewedAt: now)],
      goal: goal(createdAt: now),
      now: now,
    );
    deps.settings.dailyReviewCap = 1;

    final viewModel = await create(deps);

    expect(viewModel.uiState.dueCount, 0);
    expect(viewModel.uiState.isReviewCapReached, isTrue);
  });

  test('refresh picks up the passage of time', () async {
    final deps = FakeDependencies(
      items: kanaItems(hiraganaCount: 12, introduced: 1),
      cards: [
        reviewCard(
          id: 1,
          itemId: 1,
          due: now.add(const Duration(hours: 1)).toUtc(),
        ),
      ],
      goal: goal(createdAt: now),
      now: now,
    );
    final viewModel = await create(deps);
    expect(viewModel.uiState.dueCount, 0);

    deps.now = now.add(const Duration(hours: 2));
    await viewModel.refresh();

    expect(viewModel.uiState.dueCount, 1);
  });

  test('shows the voice notice once when no Japanese voice exists', () async {
    final deps = FakeDependencies(
      items: kanaItems(hiraganaCount: 12),
      japaneseVoiceAvailable: false,
    );
    final viewModel = await create(deps);
    expect(viewModel.uiState.showVoiceNotice, isTrue);

    await viewModel.dismissVoiceNotice();

    expect(viewModel.uiState.showVoiceNotice, isFalse);
    expect(deps.settings.voiceNoticeShown, isTrue);
  });

  test('listening cards are not counted without a voice', () async {
    final viewModel = await create(
      FakeDependencies(
        items: kanaItems(hiraganaCount: 12, introduced: 1),
        cards: [
          reviewCard(id: 1, itemId: 1, due: now.toUtc()),
          reviewCard(
            id: 2,
            itemId: 1,
            promptType: PromptType.soundToCharChoice,
            due: now.toUtc(),
          ),
        ],
        goal: goal(createdAt: now),
        now: now,
        japaneseVoiceAvailable: false,
      ),
    );

    expect(viewModel.uiState.dueCount, 1);
  });

  test('marks the goal as missed once its deadline has passed', () async {
    final deps = FakeDependencies(
      items: kanaItems(hiraganaCount: 12, introduced: 3),
      goal: goal(createdAt: DateTime(2025, 12, 1)),
      now: now,
    );

    final viewModel = await create(deps);

    expect((await deps.goals.getCurrentGoal())!.status, GoalStatus.missed);
    expect(viewModel.uiState.goal!.status, GoalStatus.missed);
    expect(viewModel.uiState.progress!.status, GoalStatus.missed);
  });
}
