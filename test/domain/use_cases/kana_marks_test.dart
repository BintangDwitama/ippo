import 'dart:math';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ippo/data/repositories/drift_backup_repository.dart';
import 'package:ippo/data/repositories/drift_card_repository.dart';
import 'package:ippo/data/repositories/drift_item_repository.dart';
import 'package:ippo/data/repositories/drift_settings_repository.dart';
import 'package:ippo/data/repositories/item_payload_mapper.dart';
import 'package:ippo/data/services/app_database.dart';
import 'package:ippo/domain/backup_codec.dart';
import 'package:ippo/domain/models/goal.dart';
import 'package:ippo/domain/models/item.dart';
import 'package:ippo/domain/models/kana_status.dart';
import 'package:ippo/domain/models/review_card.dart';
import 'package:ippo/domain/models/scheduling_state.dart';
import 'package:ippo/domain/use_cases/build_choice_options.dart';
import 'package:ippo/domain/use_cases/complete_lesson.dart';
import 'package:ippo/domain/use_cases/get_kana_status.dart';
import 'package:ippo/domain/use_cases/get_next_lesson.dart';

import '../../fakes/fake_repositories.dart';
import '../../fakes/fake_scheduler.dart';
import '../../support/builders.dart';
import '../../support/seed_items.dart';

void main() {
  final now = DateTime(2026, 1, 10, 9);
  final earlier = DateTime(2026, 1, 2, 9);

  bool isHiragana(KanaPayload k) => k.script == KanaScript.hiragana;

  group('GetNextLesson', () {
    const getNextLesson = GetNextLesson();

    List<String> lesson({bool Function(KanaPayload)? introduced, Goal? goal}) {
      return charactersOf(
        getNextLesson(
          items: seedKanaItems(introduced: introduced, introducedAt: earlier),
          goal: goal,
          now: now,
        ),
      );
    }

    test('teaches the hiragana mark after the combination kana, alone', () {
      expect(lesson(introduced: (k) => isHiragana(k) && !k.isMark), ['っ']);
    });

    test('does not teach the mark while combination kana remain', () {
      bool allButPyAndMark(KanaPayload k) =>
          isHiragana(k) && k.row != 'py' && !k.isMark;

      expect(lesson(introduced: allButPyAndMark), ['ぴゃ', 'ぴゅ', 'ぴょ']);
    });

    test('moves to katakana only after the hiragana mark', () {
      expect(lesson(introduced: isHiragana), ['ア', 'イ', 'ウ', 'エ', 'オ']);
    });

    test('teaches the two katakana marks together, last of all', () {
      expect(lesson(introduced: (k) => !k.isMark || isHiragana(k)), ['ッ', 'ー']);
      expect(lesson(introduced: (_) => true), isEmpty);
    });

    test('a voiced and combination goal includes its script\'s mark', () {
      final extended = goal(
        createdAt: now,
        targetSet: GoalTargetSet.hiraganaExtended,
      );

      expect(
        lesson(introduced: (k) => isHiragana(k) && !k.isMark, goal: extended),
        ['っ'],
      );
    });

    test('a basic goal never offers a mark', () {
      expect(
        lesson(
          introduced: (k) => isHiragana(k) && !k.isMark,
          goal: goal(createdAt: now),
        ),
        isEmpty,
      );
    });
  });

  group('CompleteLesson', () {
    late FakeItemRepository items;
    late FakeCardRepository cards;
    late CompleteLesson completeLesson;

    setUp(() {
      items = FakeItemRepository(seedKanaItems());
      cards = FakeCardRepository();
      completeLesson = CompleteLesson(
        itemRepository: items,
        cardRepository: cards,
        unitOfWork: FakeUnitOfWork(),
        scheduler: FakeScheduler(),
      );
    });

    test('introduces a mark without creating cards for it', () async {
      final mark = kanaOf(await items.getItems(), 'っ');

      await completeLesson(items: [mark], now: now);

      expect(kanaOf(await items.getItems(), 'っ').introducedAt, now);
      expect(await cards.getCards(), isEmpty);
    });

    test('introduces both katakana marks without cards', () async {
      final all = await items.getItems();

      await completeLesson(
        items: [kanaOf(all, 'ッ'), kanaOf(all, 'ー')],
        now: now,
      );

      final after = await items.getItems();
      expect(kanaOf(after, 'ッ').isIntroduced, isTrue);
      expect(kanaOf(after, 'ー').isIntroduced, isTrue);
      expect(await cards.getCards(), isEmpty);
    });

    test('still creates two cards for each ordinary kana', () async {
      final all = await items.getItems();
      final ka = kanaOf(all, 'か');
      final mark = kanaOf(all, 'っ');

      await completeLesson(items: [ka, mark], now: now);

      final created = await cards.getCards();
      expect(created, hasLength(2));
      expect(created.every((card) => card.itemId == ka.id), isTrue);
      expect(created.map((card) => card.promptType).toSet(), {
        PromptType.charToSoundChoice,
        PromptType.soundToCharChoice,
      });
      expect(kanaOf(await items.getItems(), 'っ').isIntroduced, isTrue);
    });
  });

  group('GetKanaStatus', () {
    const getKanaStatus = GetKanaStatus();

    test('a mark is not started until its lesson is done', () {
      final mark = kanaOf(seedKanaItems(), 'っ');

      expect(getKanaStatus(mark, const []), KanaStatus.notStarted);
    });

    test('a mark is known once introduced, though it has no cards', () {
      final mark = kanaOf(seedKanaItems(introduced: (k) => k.isMark), 'ー');

      expect(getKanaStatus(mark, const []), KanaStatus.known);
    });

    test('an ordinary kana without mature cards is still learning', () {
      final ka = kanaOf(seedKanaItems(introduced: (_) => true), 'か');

      expect(getKanaStatus(ka, const []), KanaStatus.learning);
      expect(
        getKanaStatus(ka, [
          reviewCard(
            id: 1,
            itemId: ka.id,
            phase: CardPhase.review,
            stability: 30,
          ),
        ]),
        KanaStatus.known,
      );
    });
  });

  group('BuildChoiceOptions', () {
    const buildChoiceOptions = BuildChoiceOptions();

    test('never offers a mark, even when every kana has been learned', () {
      final items = seedKanaItems(introduced: (_) => true);
      for (final character in ['ア', 'ツ', 'シ', 'カ', 'キャ']) {
        for (var seed = 0; seed < 20; seed++) {
          final options = charactersOf(
            buildChoiceOptions(
              correct: kanaOf(items, character),
              allItems: items,
              random: Random(seed),
            ),
          );
          expect(options, hasLength(4));
          expect(options, isNot(contains('ッ')), reason: character);
          expect(options, isNot(contains('ー')), reason: character);
        }
      }
    });

    test('never offers the hiragana mark against つ', () {
      final items = seedKanaItems(introduced: (_) => true);
      for (var seed = 0; seed < 20; seed++) {
        final options = charactersOf(
          buildChoiceOptions(
            correct: kanaOf(items, 'つ'),
            allItems: items,
            random: Random(seed),
          ),
        );
        expect(options, isNot(contains('っ')));
      }
    });
  });

  test('the payload mapper keeps a mark\'s sample', () {
    const mapper = ItemPayloadMapper();
    final mark = kanaOf(seedKanaItems(), 'っ').kana;

    final decoded =
        mapper.decode(ItemKind.kana, mapper.encode(mark)) as KanaPayload;

    expect(decoded.group, KanaGroup.mark);
    expect(decoded.sample, 'きて、きって');
    expect(decoded.spoken, 'きて、きって');
    // An ordinary kana stores no sample at all.
    final ka = kanaOf(seedKanaItems(), 'か').kana;
    expect(mapper.encode(ka), isNot(contains('sample')));
  });

  group('seeding the marks into an existing install', () {
    late AppDatabase db;

    setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);
    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('adds three kana and keeps the learner\'s data', () async {
      final items = DriftItemRepository(db);
      final cards = DriftCardRepository(db);
      final backups = DriftBackupRepository(db, DriftSettingsRepository(db));
      const codec = BackupCodec();
      final at = DateTime.utc(2026, 11, 22);

      // The app as it was before this change: 208 kana, no marks.
      await items.syncSeedItems([
        for (final seed in realSeed())
          if (!(seed.payload as KanaPayload).isMark) seed,
      ]);
      final before = await items.getItems();
      expect(before, hasLength(208));
      final learned = before.take(10).toList();
      await items.markIntroduced([for (final i in learned) i.id], at);
      for (final item in learned) {
        await cards.createCard(
          itemId: item.id,
          promptType: PromptType.charToSoundChoice,
          scheduling: SchedulingState(phase: CardPhase.learning, due: at),
          createdAt: at,
        );
      }
      final dataBefore = codec.encode(await backups.readSnapshot(at));

      await items.syncSeedItems(realSeed());

      final after = await items.getItems();
      expect(after, hasLength(211));
      expect(after.where((i) => i.kana.isMark).map((i) => i.key), [
        'hiragana:sokuon',
        'katakana:sokuon',
        'katakana:choon',
      ]);
      expect(after.where((i) => i.kana.isMark && i.isIntroduced), isEmpty);
      expect(codec.encode(await backups.readSnapshot(at)), dataBefore);
      expect(await cards.getCards(), hasLength(10));
      // Existing kana keep their ids.
      for (final item in before) {
        expect(after.firstWhere((i) => i.key == item.key).id, item.id);
      }
    });
  });
}
