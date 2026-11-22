import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ippo/data/repositories/drift_backup_repository.dart';
import 'package:ippo/data/repositories/drift_card_repository.dart';
import 'package:ippo/data/repositories/drift_item_repository.dart';
import 'package:ippo/data/repositories/drift_review_repository.dart';
import 'package:ippo/data/repositories/drift_settings_repository.dart';
import 'package:ippo/data/repositories/drift_unit_of_work.dart';
import 'package:ippo/data/seed/word_seed_loader.dart';
import 'package:ippo/data/services/app_database.dart';
import 'package:ippo/domain/backup_codec.dart';
import 'package:ippo/domain/models/backup_snapshot.dart';
import 'package:ippo/domain/models/item.dart';
import 'package:ippo/domain/models/rating.dart';
import 'package:ippo/domain/models/review_card.dart';
import 'package:ippo/domain/models/scheduling_state.dart';
import 'package:ippo/domain/models/seed_item.dart';
import 'package:ippo/domain/scheduling/fsrs_scheduler.dart';
import 'package:ippo/domain/use_cases/complete_lesson.dart';
import 'package:ippo/domain/use_cases/grade_answer.dart';
import 'package:ippo/domain/use_cases/read_backup.dart';
import 'package:ippo/ui/backup/backup_ui_state.dart';
import 'package:ippo/ui/backup/backup_view_model.dart';

import '../../support/backup_builders.dart';
import '../../support/builders.dart';
import '../../support/fake_dependencies.dart';

void main() {
  const codec = BackupCodec();
  final now = DateTime(2026, 11, 22, 9);
  final learnedAt = DateTime.utc(2026, 11, 20, 11);

  BackupCard wordCard(String key, PromptType type) => BackupCard(
        itemKey: key,
        promptType: type,
        scheduling: SchedulingState(
          phase: CardPhase.learning,
          step: 0,
          due: DateTime.utc(2026, 11, 23),
        ),
        createdAt: learnedAt,
        reviews: [
          BackupReview(
            reviewedAt: DateTime.utc(2026, 11, 21),
            rating: Rating.good,
            wasCorrect: true,
            phaseBefore: CardPhase.learning,
            elapsedDays: 0,
          ),
        ],
      );

  /// The usual two kana, plus the words named by [wordKeys] with both
  /// cards each.
  BackupSnapshot withWords(List<String> wordKeys) {
    final base = fullSnapshot();
    return BackupSnapshot(
      exportedAt: base.exportedAt,
      introducedItems: [
        ...base.introducedItems,
        for (final key in wordKeys)
          BackupItem(key: key, introducedAt: learnedAt),
      ],
      learnerMnemonics: base.learnerMnemonics,
      cards: [
        ...base.cards,
        for (final key in wordKeys) ...[
          wordCard(key, PromptType.wordToMeaningChoice),
          wordCard(key, PromptType.meaningToWordChoice),
        ],
      ],
      goals: base.goals,
      settings: base.settings,
    );
  }

  FakeDependencies appWithWords() => FakeDependencies(
        items: [
          ...kanaItems(hiraganaCount: 12),
          wordItem(id: 900, reading: 'あい'),
          wordItem(id: 901, reading: 'いえ'),
        ],
        now: now,
      );

  group('the backup format', () {
    test('is version 3 and carries word cards', () {
      final text = codec.encode(withWords(['word:900']));
      expect(text, contains('"formatVersion":3'));
      expect(text, contains('"wordToMeaningChoice"'));

      final back = codec.decode(text);
      expect(back.introducedItems.map((i) => i.key), contains('word:900'));
      expect(
        back.cards.where((c) => c.itemKey == 'word:900').map((c) => c.promptType),
        [PromptType.wordToMeaningChoice, PromptType.meaningToWordChoice],
      );
    });

    test('files of versions 1 and 2 are still read, with no words', () {
      for (final name in ['backup_v1.json', 'backup_v2.json']) {
        final snapshot =
            codec.decode(File('test/fixtures/$name').readAsStringSync());
        final summary = BackupSummary.of(snapshot);
        expect(summary.wordCount, 0, reason: name);
        expect(summary.introducedCount, greaterThan(0), reason: name);
      }
    });

    test('a reader that knows only version 2 refuses a version 3 file', () {
      // What the previous version of the app does with a new file: its
      // newest version is 2, so this file is "newer". Shown here by
      // raising this app's own file by one.
      final newer = codec
          .encode(withWords(['word:900']))
          .replaceFirst('"formatVersion":3', '"formatVersion":4');
      expect(
        () => codec.decode(newer),
        throwsA(
          isA<BackupFormatException>().having(
            (e) => e.problem,
            'problem',
            BackupFormatProblem.newerVersion,
          ),
        ),
      );
    });
  });

  group('reading a backup with words', () {
    test('the summary counts kana and words apart', () async {
      final deps = appWithWords();
      final preview = await deps.app.readBackup(
        text: codec.encode(withWords(['word:900', 'word:901'])),
        now: now,
      );
      expect(preview.inFile.introducedCount, 2);
      expect(preview.inFile.wordCount, 2);
      expect(preview.inFile.cardCount, 7);
      expect(preview.onPhone.wordCount, 0);
      expect(preview.skippedWords, 0);
    });

    test('a word this app does not have is left out and counted', () async {
      final deps = appWithWords();
      final preview = await deps.app.readBackup(
        text: codec.encode(withWords(['word:900', 'word:555'])),
        now: now,
      );

      expect(preview.skippedWords, 1);
      expect(preview.inFile.wordCount, 1);
      expect(preview.snapshot.itemKeys, isNot(contains('word:555')));
      expect(preview.snapshot.itemKeys, contains('word:900'));
      // Its two cards and their reviews go with it; the rest stays.
      expect(preview.inFile.cardCount, 5);
      expect(preview.inFile.reviewCount, 2 + 2);
      expect(preview.snapshot.goals, hasLength(2));
    });

    test('an unknown kana still refuses the whole file', () async {
      final deps = appWithWords();
      final base = withWords(['word:555']);
      final text = codec.encode(
        BackupSnapshot(
          exportedAt: base.exportedAt,
          introducedItems: [
            ...base.introducedItems,
            BackupItem(key: 'hiragana:kya', introducedAt: learnedAt),
          ],
          cards: base.cards,
        ),
      );
      await expectLater(
        deps.app.readBackup(text: text, now: now),
        throwsA(
          isA<BackupFormatException>()
              .having(
                (e) => e.problem,
                'problem',
                BackupFormatProblem.unknownItems,
              )
              .having((e) => e.detail, 'detail', 'hiragana:kya'),
        ),
      );
    });

    test('the backup screen is told how many words will be left out',
        () async {
      final deps = appWithWords();
      deps.backupFiles.fileToPick =
          codec.encode(withWords(['word:900', 'word:555', 'word:556']));
      final viewModel = BackupViewModel(deps.app);
      addTearDown(viewModel.dispose);
      await pumpEventQueue();

      await viewModel.pickImportFile();

      final state = viewModel.uiState as BackupConfirming;
      expect(state.skippedWords, 2);
      expect(state.inFile.wordCount, 1);

      await viewModel.confirmImport();
      expect(deps.backups.replaced.single.itemKeys, isNot(contains('word:555')));
    });
  });

  group('a real database', () {
    setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

    /// An install holding two kana and three words.
    Future<
        ({
          AppDatabase db,
          DriftItemRepository items,
          DriftCardRepository cards,
          DriftReviewRepository reviews,
          DriftBackupRepository backups,
        })> install() async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final items = DriftItemRepository(db);
      await items.syncSeedItems([
        for (final (index, (romaji, character))
            in const [('a', 'あ'), ('i', 'い')].indexed)
          SeedItem(
            kind: ItemKind.kana,
            key: 'hiragana:$romaji',
            sortOrder: index,
            payload: KanaPayload(
              character: character,
              script: KanaScript.hiragana,
              romaji: romaji,
            ),
            defaultMnemonic: 'mnemonic for $romaji',
          ),
        for (final (index, reading) in const ['あい', 'いい', 'ああ'].indexed)
          SeedItem(
            kind: ItemKind.word,
            key: 'word:${index + 1}',
            sortOrder: WordSeedLoader.sortOrderBase + index,
            payload: WordPayload(
              reading: reading,
              meanings: ['meaning $index'],
              partOfSpeech: 'noun',
              level: 5,
              kanaKeys: const ['hiragana:a', 'hiragana:i'],
            ),
          ),
      ]);
      return (
        db: db,
        items: items,
        cards: DriftCardRepository(db),
        reviews: DriftReviewRepository(db),
        backups: DriftBackupRepository(db, DriftSettingsRepository(db)),
      );
    }

    test('word progress survives export and import into a fresh install',
        () async {
      final first = await install();
      final scheduler = FsrsScheduler();
      final unitOfWork = DriftUnitOfWork(first.db);
      final all = await first.items.getItems();
      await CompleteLesson(
        itemRepository: first.items,
        cardRepository: first.cards,
        unitOfWork: unitOfWork,
        scheduler: scheduler,
      )(items: all.where((i) => i.isWord).take(2).toList(), now: now);
      final card = (await first.cards.getCards()).first;
      await GradeAnswer(
        cardRepository: first.cards,
        reviewRepository: first.reviews,
        unitOfWork: unitOfWork,
        scheduler: scheduler,
      )(card: card, wasCorrect: true, now: now.add(const Duration(minutes: 5)));

      final text = codec.encode(await first.backups.readSnapshot(now));

      final second = await install();
      final preview = await ReadBackup(
        backupRepository: second.backups,
        itemRepository: second.items,
      )(text: text, now: now);
      expect(preview.inFile.wordCount, 2);
      expect(preview.inFile.introducedCount, 0);
      await second.backups.replaceWith(preview.snapshot);

      final restored = await second.items.getItems();
      expect(
        restored.where((i) => i.isIntroduced).map((i) => i.key),
        ['word:1', 'word:2'],
      );
      final cardsBefore = await first.cards.getCards();
      final cardsAfter = await second.cards.getCards();
      expect(cardsAfter, hasLength(4));
      expect(
        cardsAfter.map((c) => (c.promptType, c.due, c.reps)).toSet(),
        cardsBefore.map((c) => (c.promptType, c.due, c.reps)).toSet(),
      );
      expect(await second.reviews.getReviews(), hasLength(1));
      // The word's own content comes from the app, not from the file.
      expect(restored.firstWhere((i) => i.key == 'word:1').word.reading, 'あい');
    });
  });
}
