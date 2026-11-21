import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show TableUpdate, Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ippo/data/repositories/drift_backup_repository.dart';
import 'package:ippo/data/repositories/drift_card_repository.dart';
import 'package:ippo/data/repositories/drift_goal_repository.dart';
import 'package:ippo/data/repositories/drift_item_repository.dart';
import 'package:ippo/data/repositories/drift_mnemonic_repository.dart';
import 'package:ippo/data/repositories/drift_review_repository.dart';
import 'package:ippo/data/repositories/drift_settings_repository.dart';
import 'package:ippo/data/repositories/item_payload_mapper.dart';
import 'package:ippo/data/services/app_database.dart';
import 'package:ippo/domain/backup_codec.dart';
import 'package:ippo/domain/models/goal.dart';
import 'package:ippo/domain/models/item.dart';
import 'package:ippo/domain/models/rating.dart';
import 'package:ippo/domain/models/review_card.dart';
import 'package:ippo/domain/models/scheduling_state.dart';
import 'package:ippo/domain/models/seed_item.dart';
import 'package:ippo/domain/use_cases/get_goal_progress.dart';

import '../../support/seed_items.dart';

void main() {
  const codec = BackupCodec();
  final t0 = DateTime.utc(2026, 11, 20, 11);
  final exportTime = DateTime.utc(2026, 11, 22, 2);

  late AppDatabase db;
  late DriftItemRepository items;
  late DriftMnemonicRepository mnemonics;
  late DriftCardRepository cards;
  late DriftReviewRepository reviews;
  late DriftGoalRepository goals;
  late DriftBackupRepository backups;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    items = DriftItemRepository(db);
    mnemonics = DriftMnemonicRepository(db);
    cards = DriftCardRepository(db);
    reviews = DriftReviewRepository(db);
    goals = DriftGoalRepository(db);
    backups = DriftBackupRepository(db, DriftSettingsRepository(db));
  });

  tearDown(() => db.close());

  /// Fills the database exactly as the previous version of the app did:
  /// 92 kana, payloads without group or row, katakana ordered from 100.
  Future<void> seedAsPreviousVersion() async {
    final entries =
        jsonDecode(File('test/fixtures/kana_seed_v1.json').readAsStringSync())
            as List<Object?>;
    for (final entry in entries.cast<Map<String, Object?>>()) {
      final id = await db
          .into(db.items)
          .insert(
            ItemsCompanion.insert(
              kind: ItemKind.kana,
              itemKey: '${entry['script']}:${entry['romaji']}',
              payload: jsonEncode({
                'character': entry['character'],
                'script': entry['script'],
                'romaji': entry['romaji'],
                'alt': entry['alt'],
              }),
              sortOrder: entry['order']! as int,
            ),
          );
      await db
          .into(db.mnemonics)
          .insert(
            MnemonicsCompanion.insert(
              itemId: Value(id),
              defaultText: entry['mnemonic']! as String,
            ),
          );
    }
  }

  /// A learner ten kana in, with cards, reviews, a goal and one mnemonic
  /// of their own.
  Future<void> study() async {
    final all = await items.getItems();
    final firstTen = all.take(10).toList();
    await items.markIntroduced([for (final i in firstTen) i.id], t0);
    await mnemonics.saveLearnerText(firstTen[1].id, 'two eels side by side');
    for (final item in firstTen) {
      for (final prompt in [
        PromptType.charToSoundChoice,
        PromptType.soundToCharChoice,
      ]) {
        final card = await cards.createCard(
          itemId: item.id,
          promptType: prompt,
          scheduling: SchedulingState(
            phase: CardPhase.learning,
            step: 0,
            due: t0.add(const Duration(minutes: 10)),
          ),
          createdAt: t0,
        );
        await reviews.addReview(
          cardId: card.id,
          reviewedAt: t0.add(const Duration(minutes: 5)),
          rating: Rating.good,
          wasCorrect: true,
          phaseBefore: CardPhase.learning,
          elapsedDays: 0,
        );
      }
    }
    await goals.createGoal(
      targetSet: GoalTargetSet.hiragana,
      targetAccuracy: 0.9,
      createdAt: t0,
      deadline: t0.add(const Duration(days: 14)),
    );
  }

  Future<String> learnerData() async =>
      codec.encode(await backups.readSnapshot(exportTime));

  test('the previous version\'s payloads still read as basic kana', () async {
    await seedAsPreviousVersion();

    final all = await items.getItems();
    expect(all, hasLength(92));
    expect(all.every((i) => i.kana.group == KanaGroup.basic), isTrue);
    expect(all.first.kana.row, isEmpty);
    expect(all.first.kana.family, 'a');
  });

  test('updating from 92 kana keeps all learner data', () async {
    await seedAsPreviousVersion();
    await study();
    final before = await learnerData();
    final idsBefore = {
      for (final item in await items.getItems()) item.key: item.id,
    };

    await items.syncSeedItems(realSeed());

    expect(await learnerData(), before);
    final after = await items.getItems();
    expect(after, hasLength(211));
    expect(after.where((i) => i.isIntroduced), hasLength(10));
    expect(await cards.getCards(), hasLength(20));
    expect(await reviews.getReviews(), hasLength(20));
    // Cards point at items by id, so ids must not move.
    for (final item in after) {
      if (idsBefore.containsKey(item.key)) {
        expect(item.id, idsBefore[item.key], reason: item.key);
      }
    }
    expect(
      (await mnemonics.getMnemonic(idsBefore['hiragana:i']!)).text,
      'two eels side by side',
    );
  });

  test('updating gives the existing kana their new content', () async {
    await seedAsPreviousVersion();
    await study();

    await items.syncSeedItems(realSeed());

    final all = await items.getItems();
    Item of(String key) => all.firstWhere((i) => i.key == key);
    expect(of('hiragana:ka').kana.row, 'k');
    expect(of('hiragana:ka').kana.group, KanaGroup.basic);
    expect(of('hiragana:nu').kana.lookalikes, contains('め'));
    expect(of('hiragana:ka').isIntroduced, isTrue);
    // Katakana moved behind the new hiragana.
    expect(of('katakana:a').sortOrder, 1000);
    expect(of('hiragana:ga').sortOrder, lessThan(of('katakana:a').sortOrder));
    expect(of('hiragana:kya').kana.group, KanaGroup.combination);
    expect(of('hiragana:di').kana.character, 'ぢ');
    expect(
      charactersOf(all).take(46).toList(),
      charactersOf(seedKanaItems()).take(46).toList(),
    );
  });

  test('an existing hiragana goal still counts 46 kana', () async {
    await seedAsPreviousVersion();
    await study();

    await items.syncSeedItems(realSeed());

    final progress = const GetGoalProgress()(
      goal: (await goals.getCurrentGoal())!,
      items: await items.getItems(),
      cards: await cards.getCards(),
      reviews: await reviews.getReviews(),
      now: t0.add(const Duration(hours: 1)),
    );
    expect(progress.introducedCount, 10);
    expect(progress.totalCount, 46);
  });

  test('a second sync writes nothing', () async {
    await seedAsPreviousVersion();
    await items.syncSeedItems(realSeed());
    final writes = <Set<TableUpdate>>[];
    final subscription = db.tableUpdates().listen(writes.add);
    addTearDown(subscription.cancel);

    await items.syncSeedItems(realSeed());
    await pumpEventQueue();

    expect(writes, isEmpty);
    expect(await items.getItems(), hasLength(211));
  });

  test(
    'a changed default mnemonic reaches kana the learner has not edited',
    () async {
      await seedAsPreviousVersion();
      await study();
      final changed = [
        for (final seed in realSeed())
          SeedItem(
            kind: seed.kind,
            key: seed.key,
            sortOrder: seed.sortOrder,
            payload: seed.payload,
            defaultMnemonic:
                seed.key == 'hiragana:a' || seed.key == 'hiragana:i'
                ? 'a better hint'
                : seed.defaultMnemonic,
          ),
      ];

      await items.syncSeedItems(changed);

      final all = await items.getItems();
      int idOf(String key) => all.firstWhere((i) => i.key == key).id;
      expect(
        (await mnemonics.getMnemonic(idOf('hiragana:a'))).text,
        'a better hint',
      );
      // The learner's own text still wins, and the new default waits
      // behind it.
      final edited = await mnemonics.getMnemonic(idOf('hiragana:i'));
      expect(edited.text, 'two eels side by side');
      expect(edited.defaultText, 'a better hint');
    },
  );

  test('a fresh install gets all 211 kana', () async {
    await items.syncSeedItems(realSeed());

    final all = await items.getItems();
    expect(all, hasLength(211));
    expect(all.where((i) => i.isIntroduced), isEmpty);
    expect(charactersOf(all).take(5).toList(), ['あ', 'い', 'う', 'え', 'お']);
  });

  test('the payload mapper round-trips every field', () {
    const mapper = ItemPayloadMapper();
    const payload = KanaPayload(
      character: 'ぢ',
      script: KanaScript.hiragana,
      romaji: 'ji',
      alternativeRomaji: ['di'],
      group: KanaGroup.voiced,
      row: 'd',
      family: 'chi',
      lookalikes: ['じ'],
    );

    final decoded =
        mapper.decode(ItemKind.kana, mapper.encode(payload)) as KanaPayload;

    expect(decoded.character, 'ぢ');
    expect(decoded.alternativeRomaji, ['di']);
    expect(decoded.group, KanaGroup.voiced);
    expect(decoded.row, 'd');
    expect(decoded.family, 'chi');
    expect(decoded.lookalikes, ['じ']);
  });
}
