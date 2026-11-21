import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ippo/data/repositories/drift_card_repository.dart';
import 'package:ippo/data/repositories/drift_goal_repository.dart';
import 'package:ippo/data/repositories/drift_item_repository.dart';
import 'package:ippo/data/repositories/drift_mnemonic_repository.dart';
import 'package:ippo/data/repositories/drift_review_repository.dart';
import 'package:ippo/data/repositories/drift_settings_repository.dart';
import 'package:ippo/data/repositories/drift_unit_of_work.dart';
import 'package:ippo/data/repositories/settings_repository.dart';
import 'package:ippo/data/services/app_database.dart';
import 'package:ippo/domain/models/goal.dart';
import 'package:ippo/domain/models/item.dart';
import 'package:ippo/domain/models/rating.dart';
import 'package:ippo/domain/models/reminder_time.dart';
import 'package:ippo/domain/models/review_card.dart';
import 'package:ippo/domain/models/scheduling_state.dart';
import 'package:ippo/domain/models/seed_item.dart';

SeedItem _seed(String romaji, String character, int order) {
  return SeedItem(
    kind: ItemKind.kana,
    key: 'hiragana:$romaji',
    sortOrder: order,
    payload: KanaPayload(
      character: character,
      script: KanaScript.hiragana,
      romaji: romaji,
      alternativeRomaji: romaji == 'shi' ? const ['si'] : const [],
    ),
    defaultMnemonic: 'default for $romaji',
  );
}

void main() {
  late AppDatabase db;
  late DriftItemRepository items;
  late DriftMnemonicRepository mnemonics;
  late DriftCardRepository cards;
  late DriftReviewRepository reviews;
  late DriftGoalRepository goals;
  late DriftSettingsRepository settings;

  final now = DateTime.utc(2026, 1, 1, 9);
  final newState =
      SchedulingState(phase: CardPhase.learning, step: 0, due: now);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    items = DriftItemRepository(db);
    mnemonics = DriftMnemonicRepository(db);
    cards = DriftCardRepository(db);
    reviews = DriftReviewRepository(db);
    goals = DriftGoalRepository(db);
    settings = DriftSettingsRepository(db);
    await items.syncSeedItems([
      _seed('i', 'い', 1),
      _seed('a', 'あ', 0),
      _seed('shi', 'し', 11),
    ]);
  });

  tearDown(() => db.close());

  group('DriftItemRepository', () {
    test('returns items in teaching order with decoded payloads', () async {
      final all = await items.getItems();

      expect(all.map((i) => i.kana.character), ['あ', 'い', 'し']);
      expect(all.last.kana.acceptedRomaji, ['shi', 'si']);
      expect(all.every((i) => !i.isIntroduced), isTrue);
    });

    test('seeding the same keys twice does not duplicate', () async {
      await items.syncSeedItems([_seed('a', 'あ', 0), _seed('u', 'う', 2)]);

      expect(await items.getItems(), hasLength(4));
    });

    test('markIntroduced sets the date and notifies the stream', () async {
      final a = (await items.getItems()).first;
      final emissions = <List<Item>>[];
      final subscription = items.getItemsStream().listen(emissions.add);
      await pumpEventQueue();

      await items.markIntroduced([a.id], now);
      await pumpEventQueue();
      await subscription.cancel();

      expect(emissions.last.first.isIntroduced, isTrue);
      expect(emissions.last[1].isIntroduced, isFalse);
      expect((await items.getItem(a.id))!.introducedAt, isNotNull);
    });
  });

  group('DriftMnemonicRepository', () {
    test('shows the default until the learner writes their own', () async {
      final a = (await items.getItems()).first;

      expect((await mnemonics.getMnemonic(a.id)).text, 'default for a');

      await mnemonics.saveLearnerText(a.id, '  my own  ');
      final edited = await mnemonics.getMnemonic(a.id);
      expect(edited.text, 'my own');
      expect(edited.isEdited, isTrue);
    });

    test('rejects a blank mnemonic and keeps the previous one', () async {
      final a = (await items.getItems()).first;
      await mnemonics.saveLearnerText(a.id, 'mine');

      expect(() => mnemonics.saveLearnerText(a.id, '   '), throwsArgumentError);
      expect((await mnemonics.getMnemonic(a.id)).text, 'mine');
    });

    test('restoreDefault removes the learner text', () async {
      final a = (await items.getItems()).first;
      await mnemonics.saveLearnerText(a.id, 'mine');

      await mnemonics.restoreDefault(a.id);

      final restored = await mnemonics.getMnemonic(a.id);
      expect(restored.text, 'default for a');
      expect(restored.isEdited, isFalse);
    });
  });

  group('DriftCardRepository', () {
    test('creates one card per item and prompt type', () async {
      final a = (await items.getItems()).first;

      final first = await cards.createCard(
        itemId: a.id,
        promptType: PromptType.charToSoundChoice,
        scheduling: newState,
        createdAt: now,
      );
      final duplicate = await cards.createCard(
        itemId: a.id,
        promptType: PromptType.charToSoundChoice,
        scheduling: newState,
        createdAt: now,
      );
      await cards.createCard(
        itemId: a.id,
        promptType: PromptType.soundToCharChoice,
        scheduling: newState,
        createdAt: now,
      );

      expect(duplicate.id, first.id);
      expect(await cards.getCards(), hasLength(2));
      expect(first.isDueAt(now), isTrue);
      expect(first.due.isUtc, isTrue);
    });

    test('updateCard persists the schedule and counters', () async {
      final a = (await items.getItems()).first;
      final card = await cards.createCard(
        itemId: a.id,
        promptType: PromptType.charToSoundChoice,
        scheduling: newState,
        createdAt: now,
      );
      final due = now.add(const Duration(days: 3));

      await cards.updateCard(
        card.copyWith(
          scheduling: SchedulingState(
            phase: CardPhase.review,
            due: due,
            stability: 3.2,
            difficulty: 5.1,
            lastReview: now,
          ),
          reps: 2,
          lapses: 1,
          consecutiveCorrect: 2,
        ),
      );

      final saved = (await cards.getCards()).single;
      expect(saved.scheduling.phase, CardPhase.review);
      expect(saved.due, due);
      expect(saved.scheduling.stability, 3.2);
      expect(saved.scheduling.step, isNull);
      expect(saved.scheduling.lastReview, now);
      expect(saved.reps, 2);
      expect(saved.lapses, 1);
      expect(saved.consecutiveCorrect, 2);
    });
  });

  group('DriftReviewRepository', () {
    test('stores review records oldest first', () async {
      final a = (await items.getItems()).first;
      final card = await cards.createCard(
        itemId: a.id,
        promptType: PromptType.charToSoundChoice,
        scheduling: newState,
        createdAt: now,
      );

      await reviews.addReview(
        cardId: card.id,
        reviewedAt: now,
        rating: Rating.again,
        wasCorrect: false,
        phaseBefore: CardPhase.learning,
        elapsedDays: 0,
      );
      await reviews.addReview(
        cardId: card.id,
        reviewedAt: now.add(const Duration(days: 1)),
        rating: Rating.good,
        wasCorrect: true,
        phaseBefore: CardPhase.learning,
        elapsedDays: 1,
      );

      final all = await reviews.getReviews();
      expect(all.map((r) => r.wasCorrect), [false, true]);
      expect(all.first.rating, Rating.again);
      expect(all.first.reviewedAt, now);
      expect(all.last.elapsedDays, 1);
    });
  });

  group('DriftGoalRepository', () {
    test('the current goal is the most recently created', () async {
      expect(await goals.getCurrentGoal(), isNull);

      await goals.createGoal(
        targetSet: GoalTargetSet.hiragana,
        targetAccuracy: 0.9,
        createdAt: now,
        deadline: now.add(const Duration(days: 14)),
      );
      final second = await goals.createGoal(
        targetSet: GoalTargetSet.katakana,
        targetAccuracy: 0.8,
        createdAt: now,
        deadline: now.add(const Duration(days: 7)),
      );

      final current = await goals.getCurrentGoal();
      expect(current!.id, second.id);
      expect(current.targetSet, GoalTargetSet.katakana);
      expect(current.status, GoalStatus.active);
    });

    test('updateGoal changes the status', () async {
      final goal = await goals.createGoal(
        targetSet: GoalTargetSet.hiragana,
        targetAccuracy: 0.9,
        createdAt: now,
        deadline: now.add(const Duration(days: 14)),
      );

      await goals.updateGoal(
        Goal(
          id: goal.id,
          targetSet: goal.targetSet,
          targetAccuracy: goal.targetAccuracy,
          createdAt: goal.createdAt,
          deadline: goal.deadline,
          status: GoalStatus.achieved,
        ),
      );

      expect((await goals.getCurrentGoal())!.status, GoalStatus.achieved);
    });
  });

  group('DriftSettingsRepository', () {
    test('has defaults and persists changes', () async {
      expect(
        await settings.getDailyReviewCap(),
        SettingsRepository.defaultDailyReviewCap,
      );
      expect(await settings.getReminderTime(), isNull);
      expect(await settings.isVoiceNoticeShown(), isFalse);

      await settings.setDailyReviewCap(40);
      await settings.setReminderTime(const ReminderTime(hour: 19, minute: 5));
      await settings.setVoiceNoticeShown();

      expect(await settings.getDailyReviewCap(), 40);
      expect(
        await settings.getReminderTime(),
        const ReminderTime(hour: 19, minute: 5),
      );
      expect(await settings.isVoiceNoticeShown(), isTrue);

      await settings.setReminderTime(null);
      expect(await settings.getReminderTime(), isNull);
    });

    test('rejects a cap below 1', () {
      expect(() => settings.setDailyReviewCap(0), throwsArgumentError);
    });
  });

  group('DriftUnitOfWork', () {
    test('undoes every write when the action throws', () async {
      final a = (await items.getItems()).first;
      final unitOfWork = DriftUnitOfWork(db);

      await expectLater(
        unitOfWork.run(() async {
          await items.markIntroduced([a.id], now);
          await cards.createCard(
            itemId: a.id,
            promptType: PromptType.charToSoundChoice,
            scheduling: newState,
            createdAt: now,
          );
          throw StateError('boom');
        }),
        throwsStateError,
      );

      expect((await items.getItem(a.id))!.isIntroduced, isFalse);
      expect(await cards.getCards(), isEmpty);
    });
  });
}
