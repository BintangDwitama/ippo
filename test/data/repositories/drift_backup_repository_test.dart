import 'package:drift/drift.dart' show TableUpdate, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ippo/data/repositories/backup_repository.dart';
import 'package:ippo/data/repositories/drift_backup_repository.dart';
import 'package:ippo/data/repositories/drift_card_repository.dart';
import 'package:ippo/data/repositories/drift_goal_repository.dart';
import 'package:ippo/data/repositories/drift_item_repository.dart';
import 'package:ippo/data/repositories/drift_mnemonic_repository.dart';
import 'package:ippo/data/repositories/drift_review_repository.dart';
import 'package:ippo/data/repositories/drift_settings_repository.dart';
import 'package:ippo/data/services/app_database.dart';
import 'package:ippo/domain/backup_codec.dart';
import 'package:ippo/domain/models/appearance_mode.dart';
import 'package:ippo/domain/models/backup_snapshot.dart';
import 'package:ippo/domain/models/goal.dart';
import 'package:ippo/domain/models/item.dart';
import 'package:ippo/domain/models/rating.dart';
import 'package:ippo/domain/models/reminder_time.dart';
import 'package:ippo/domain/models/review_card.dart';
import 'package:ippo/domain/models/scheduling_state.dart';
import 'package:ippo/domain/models/seed_item.dart';

import '../../support/backup_builders.dart';

const _kana = [('a', 'あ'), ('i', 'い'), ('u', 'う'), ('e', 'え')];

/// One install of the app: a database with its repositories.
class _Install {
  _Install({this._mnemonicPrefix = 'default for'})
    : db = AppDatabase(NativeDatabase.memory()) {
    items = DriftItemRepository(db);
    mnemonics = DriftMnemonicRepository(db);
    cards = DriftCardRepository(db);
    reviews = DriftReviewRepository(db);
    goals = DriftGoalRepository(db);
    settings = DriftSettingsRepository(db);
    backups = DriftBackupRepository(db, settings);
  }

  final AppDatabase db;
  final String _mnemonicPrefix;
  late final DriftItemRepository items;
  late final DriftMnemonicRepository mnemonics;
  late final DriftCardRepository cards;
  late final DriftReviewRepository reviews;
  late final DriftGoalRepository goals;
  late final DriftSettingsRepository settings;
  late final DriftBackupRepository backups;

  Future<void> seed() {
    return items.insertSeedItems([
      for (var i = 0; i < _kana.length; i++)
        SeedItem(
          kind: ItemKind.kana,
          key: 'hiragana:${_kana[i].$1}',
          sortOrder: i,
          payload: KanaPayload(
            character: _kana[i].$2,
            script: KanaScript.hiragana,
            romaji: _kana[i].$1,
          ),
          defaultMnemonic: '$_mnemonicPrefix ${_kana[i].$1}',
        ),
    ]);
  }

  /// Every row of [table] as plain values, without the columns in [drop].
  Future<List<Map<String, Object?>>> rows(
    String table, {
    Set<String> drop = const {},
  }) async {
    final result = await db.customSelect('SELECT * FROM $table').get();
    return [
      for (final row in result)
        {
          for (final entry in row.data.entries)
            if (!drop.contains(entry.key)) entry.key: entry.value,
        },
    ];
  }
}

void main() {
  const codec = BackupCodec();
  final t0 = DateTime.utc(2026, 11, 20, 11);
  final exportTime = DateTime.utc(2026, 11, 21, 2, 15);

  late _Install phone;
  late _Install newPhone;

  // Each test uses separate in-memory databases on purpose.
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() async {
    phone = _Install();
    newPhone = _Install();
    await phone.seed();
    await newPhone.seed();
  });

  tearDown(() async {
    await phone.db.close();
    await newPhone.db.close();
  });

  /// Uses the app's own repositories to put data in every table.
  Future<void> study(_Install install) async {
    final all = await install.items.getItems();
    await install.items.markIntroduced([all[0].id, all[1].id, all[2].id], t0);
    await install.mnemonics.saveLearnerText(all[1].id, 'two eels side by side');

    SchedulingState learning(int minutes) => SchedulingState(
      phase: CardPhase.learning,
      step: 0,
      due: t0.add(Duration(minutes: minutes)),
    );
    final first = await install.cards.createCard(
      itemId: all[0].id,
      promptType: PromptType.charToSoundChoice,
      scheduling: learning(1),
      createdAt: t0,
    );
    final second = await install.cards.createCard(
      itemId: all[0].id,
      promptType: PromptType.soundToCharChoice,
      scheduling: learning(2),
      createdAt: t0,
    );
    final third = await install.cards.createCard(
      itemId: all[1].id,
      promptType: PromptType.charToSoundChoice,
      scheduling: learning(3),
      createdAt: t0,
    );
    await install.cards.createCard(
      itemId: all[2].id,
      promptType: PromptType.charToSoundTyped,
      scheduling: learning(4),
      createdAt: t0.add(const Duration(hours: 1)),
    );

    await install.cards.updateCard(
      first.copyWith(
        scheduling: SchedulingState(
          phase: CardPhase.review,
          due: t0.add(const Duration(days: 4)),
          stability: 4.25,
          difficulty: 5.5,
          lastReview: t0.add(const Duration(hours: 13)),
        ),
        reps: 3,
        lapses: 1,
        consecutiveCorrect: 2,
      ),
    );

    // Reviews of different cards interleaved, as in real use.
    Future<void> review(ReviewCard card, int minutes, {bool correct = true}) {
      return install.reviews.addReview(
        cardId: card.id,
        reviewedAt: t0.add(Duration(minutes: minutes)),
        rating: correct ? Rating.good : Rating.again,
        wasCorrect: correct,
        phaseBefore: CardPhase.learning,
        elapsedDays: minutes > 600 ? 1 : 0,
      );
    }

    await review(first, 5, correct: false);
    await review(third, 6);
    await review(first, 7);
    await review(second, 8);
    await review(first, 780);

    final oldGoal = await install.goals.createGoal(
      targetSet: GoalTargetSet.hiragana,
      targetAccuracy: 0.8,
      createdAt: t0.subtract(const Duration(days: 20)),
      deadline: t0.subtract(const Duration(days: 6)),
    );
    await install.goals.updateGoal(
      Goal(
        id: oldGoal.id,
        targetSet: oldGoal.targetSet,
        targetAccuracy: oldGoal.targetAccuracy,
        createdAt: oldGoal.createdAt,
        deadline: oldGoal.deadline,
        status: GoalStatus.missed,
      ),
    );
    await install.goals.createGoal(
      targetSet: GoalTargetSet.both,
      targetAccuracy: 0.9,
      createdAt: t0,
      deadline: t0.add(const Duration(days: 14)),
    );

    await install.settings.setDailyReviewCap(60);
    await install.settings.setReminderTime(
      const ReminderTime(hour: 19, minute: 30),
    );
    await install.settings.setAppearanceMode(AppearanceMode.paper);
  }

  test('every table of the database is accounted for by the backup', () {
    final tables = {
      for (final table in phone.db.allTables) table.actualTableName,
    };

    expect(
      tables.difference(DriftBackupRepository.coveredTables),
      isEmpty,
      reason:
          'A table was added without deciding how it is backed up. '
          'Extend DriftBackupRepository (readSnapshot, replaceWith and '
          'coveredTables) and the backup format.',
    );
  });

  test('a restore on a fresh install reproduces every table', () async {
    await study(phone);
    // Device state that must not travel with a backup.
    await phone.settings.setVoiceNoticeShown();
    await phone.settings.setLastExportAt(exportTime);

    final snapshot = await phone.backups.readSnapshot(exportTime);
    await newPhone.backups.replaceWith(codec.decode(codec.encode(snapshot)));

    for (final table in ['items', 'mnemonics', 'cards', 'goals']) {
      expect(
        await newPhone.rows(table),
        await phone.rows(table),
        reason: 'table $table',
      );
    }
    // Review ids follow insertion order, which a restore groups by card.
    // Everything else about each review must match.
    String describe(Map<String, Object?> row) => '$row';
    expect(
      (await newPhone.rows(
        'review_records',
        drop: {'id'},
      )).map(describe).toSet(),
      (await phone.rows('review_records', drop: {'id'})).map(describe).toSet(),
    );
    expect(await newPhone.rows('review_records'), hasLength(5));

    const restored = {
      'daily_review_cap',
      'reminder_minutes',
      'appearance_mode',
    };
    List<Map<String, Object?>> restoredOnly(List<Map<String, Object?>> rows) =>
        rows.where((row) => restored.contains(row['name'])).toList()
          ..sort((a, b) => '${a['name']}'.compareTo('${b['name']}'));
    expect(
      restoredOnly(await newPhone.rows('settings')),
      restoredOnly(await phone.rows('settings')),
    );
    expect(restoredOnly(await newPhone.rows('settings')), hasLength(3));

    // And a second snapshot of the restored install is the same file.
    expect(
      codec.encode(await newPhone.backups.readSnapshot(exportTime)),
      codec.encode(snapshot),
    );
  });

  test('device state is not restored', () async {
    await study(phone);
    await phone.settings.setVoiceNoticeShown();
    await phone.settings.setLastExportAt(exportTime);

    await newPhone.backups.replaceWith(
      await phone.backups.readSnapshot(exportTime),
    );

    expect(await newPhone.settings.isVoiceNoticeShown(), isFalse);
    expect(await newPhone.settings.getLastExportAt(), isNull);
  });

  test('a snapshot of a new install is empty', () async {
    final snapshot = await phone.backups.readSnapshot(exportTime);

    expect(snapshot.exportedAt, exportTime);
    expect(snapshot.introducedItems, isEmpty);
    expect(snapshot.learnerMnemonics, isEmpty);
    expect(snapshot.cards, isEmpty);
    expect(snapshot.goals, isEmpty);
    expect(snapshot.settings.dailyReviewCap, 100);
    expect(snapshot.settings.reminderTime, isNull);
    expect(snapshot.settings.appearanceMode, AppearanceMode.automatic);
  });

  test('a restore removes data that is not in the snapshot', () async {
    await study(phone);
    final small = BackupSnapshot(
      exportedAt: exportTime,
      introducedItems: [BackupItem(key: 'hiragana:e', introducedAt: t0)],
    );

    await phone.backups.replaceWith(small);

    final items = await phone.items.getItems();
    expect(items.where((i) => i.isIntroduced).map((i) => i.key), [
      'hiragana:e',
    ]);
    expect(await phone.cards.getCards(), isEmpty);
    expect(await phone.reviews.getReviews(), isEmpty);
    expect(await phone.goals.getCurrentGoal(), isNull);
    expect((await phone.mnemonics.getMnemonic(items[1].id)).isEdited, isFalse);
    expect(await phone.settings.getDailyReviewCap(), 100);
    expect(await phone.settings.getReminderTime(), isNull);
    expect(await phone.settings.getAppearanceMode(), AppearanceMode.automatic);
  });

  test(
    'an unedited mnemonic keeps the default of the app restored into',
    () async {
      await study(phone);
      final improved = _Install(mnemonicPrefix: 'better hint for');
      addTearDown(improved.db.close);
      await improved.seed();

      await improved.backups.replaceWith(
        await phone.backups.readSnapshot(exportTime),
      );

      final items = await improved.items.getItems();
      expect(
        (await improved.mnemonics.getMnemonic(items[0].id)).text,
        'better hint for a',
      );
      // The learner's own text still wins where they wrote one.
      expect(
        (await improved.mnemonics.getMnemonic(items[1].id)).text,
        'two eels side by side',
      );
    },
  );

  test('a snapshot naming an unknown kana changes nothing', () async {
    await study(phone);
    final before = codec.encode(await phone.backups.readSnapshot(exportTime));

    await expectLater(
      phone.backups.replaceWith(
        fullSnapshot(keys: ['hiragana:a', 'hiragana:kya']),
      ),
      throwsA(
        isA<UnknownItemKeyException>().having(
          (e) => e.key,
          'key',
          'hiragana:kya',
        ),
      ),
    );

    expect(codec.encode(await phone.backups.readSnapshot(exportTime)), before);
  });

  test('a failure part-way through undoes the whole restore', () async {
    await study(phone);
    final before = codec.encode(await phone.backups.readSnapshot(exportTime));
    final good = fullSnapshot();
    // The same card twice breaks a database constraint after the old
    // data has already been deleted inside the transaction.
    final broken = BackupSnapshot(
      exportedAt: good.exportedAt,
      introducedItems: good.introducedItems,
      cards: [...good.cards, good.cards.first],
      goals: good.goals,
      settings: good.settings,
    );

    await expectLater(phone.backups.replaceWith(broken), throwsA(anything));

    expect(codec.encode(await phone.backups.readSnapshot(exportTime)), before);
    expect(await phone.reviews.getReviews(), hasLength(5));
  });

  test('open streams emit the restored data', () async {
    final cardCounts = <int>[];
    final goals = <GoalTargetSet?>[];
    final appearances = <AppearanceMode>[];
    final subscriptions = [
      newPhone.cards.getCardsStream().listen((c) => cardCounts.add(c.length)),
      newPhone.goals.getCurrentGoalStream().listen(
        (g) => goals.add(g?.targetSet),
      ),
      newPhone.settings.getAppearanceModeStream().listen(appearances.add),
    ];
    addTearDown(() async {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    });
    await pumpEventQueue();

    await newPhone.backups.replaceWith(fullSnapshot());
    await pumpEventQueue();

    expect(cardCounts.first, 0);
    expect(cardCounts.last, 3);
    expect(goals.first, isNull);
    expect(goals.last, GoalTargetSet.both);
    expect(appearances.last, AppearanceMode.paper);
  });

  group('last export date', () {
    test('is unknown until an export is recorded', () async {
      expect(await phone.settings.getLastExportAt(), isNull);
    });

    test('is stored and read back', () async {
      await phone.settings.setLastExportAt(exportTime);

      expect(await phone.settings.getLastExportAt(), exportTime);
      expect(
        await DriftSettingsRepository(phone.db).getLastExportAt(),
        exportTime,
      );
    });

    test('is left alone by a restore', () async {
      await phone.settings.setLastExportAt(exportTime);

      await phone.backups.replaceWith(fullSnapshot());

      expect(await phone.settings.getLastExportAt(), exportTime);
    });
  });

  test('reading a snapshot does not write to the database', () async {
    await study(phone);
    final writes = <Set<TableUpdate>>[];
    final subscription = phone.db.tableUpdates().listen(writes.add);
    addTearDown(subscription.cancel);

    await phone.backups.readSnapshot(exportTime);
    await pumpEventQueue();

    expect(writes, isEmpty);
  });
}
