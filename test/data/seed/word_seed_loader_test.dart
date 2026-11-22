import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ippo/data/repositories/drift_card_repository.dart';
import 'package:ippo/data/repositories/drift_item_repository.dart';
import 'package:ippo/data/seed/kana_seed_loader.dart';
import 'package:ippo/data/seed/word_seed_loader.dart';
import 'package:ippo/data/services/app_database.dart';
import 'package:ippo/domain/models/item.dart';
import 'package:ippo/domain/models/review_card.dart';
import 'package:ippo/domain/models/scheduling_state.dart';

void main() {
  final bundled = File(WordSeedLoader.assetPath).readAsStringSync();
  final kanaJson = File(KanaSeedLoader.assetPath).readAsStringSync();

  /// A small list in the bundled format.
  String listOf(List<Map<String, Object?>> words, {int version = 1}) {
    return jsonEncode({
      'format': 'ippo-words',
      'formatVersion': version,
      'dictionaryDate': '2026-11-16',
      'words': words,
    });
  }

  Map<String, Object?> entry(
    String id,
    String reading, {
    String? written,
    List<String> meanings = const ['meaning'],
    int order = 1,
  }) {
    return {
      'id': id,
      'reading': reading,
      'written': written,
      'meanings': meanings,
      'partOfSpeech': 'noun',
      'level': 5,
      'order': order,
      'kana': ['hiragana:a'],
    };
  }

  group('the bundled word list', () {
    final seed = WordSeedLoader.parse(bundled);

    test('parses, with its dictionary date', () {
      expect(seed.items.length, greaterThan(1000));
      expect(seed.info.dictionaryDate, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
      expect(seed.info.keys, hasLength(seed.items.length));
    });

    test('is listed among the app assets', () {
      expect(
        File('pubspec.yaml').readAsStringSync(),
        contains('- ${WordSeedLoader.assetPath}'),
      );
    });

    test('every word is a word item sorted after all kana', () {
      final lastKana = KanaSeedLoader.parse(kanaJson)
          .map((k) => k.sortOrder)
          .reduce((a, b) => a > b ? a : b);
      for (final item in seed.items) {
        expect(item.kind, ItemKind.word);
        expect(item.key, startsWith('word:'));
        expect(item.sortOrder, greaterThan(lastKana));
        expect(item.defaultMnemonic, isNull);
      }
      expect(seed.items.map((i) => i.sortOrder).toSet(),
          hasLength(seed.items.length));
    });

    test('every word needs only kana the app teaches', () {
      final kanaKeys = {for (final k in KanaSeedLoader.parse(kanaJson)) k.key};
      for (final item in seed.items) {
        final word = item.payload as WordPayload;
        expect(word.kanaKeys, isNotEmpty, reason: item.key);
        expect(kanaKeys.containsAll(word.kanaKeys), isTrue, reason: item.key);
        expect(word.meanings, isNotEmpty, reason: item.key);
      }
    });

    test('holds rain as a word with its written form', () {
      final rain = seed.items
          .map((i) => i.payload as WordPayload)
          .firstWhere((w) => w.reading == 'あめ' && w.written == '雨');
      expect(rain.meanings, ['rain']);
      expect(rain.kanaKeys, ['hiragana:a', 'hiragana:me']);
    });
  });

  group('reading a word list', () {
    test('a file of another kind is refused', () {
      expect(() => WordSeedLoader.parse('[]'), throwsFormatException);
      expect(
        () => WordSeedLoader.parse('{"format":"ippo-backup"}'),
        throwsFormatException,
      );
    });

    test('a newer format is refused', () {
      expect(
        () => WordSeedLoader.parse(listOf([entry('1', 'あ')], version: 2)),
        throwsFormatException,
      );
    });

    test('a word without meanings or kana is refused', () {
      expect(
        () => WordSeedLoader.parse(listOf([entry('1', 'あ', meanings: [])])),
        throwsFormatException,
      );
      expect(
        () => WordSeedLoader.parse(
          listOf([
            {...entry('1', 'あ'), 'kana': <String>[]},
          ]),
        ),
        throwsFormatException,
      );
    });
  });

  group('keeping words in line with the list', () {
    late AppDatabase db;
    late DriftItemRepository items;

    setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      items = DriftItemRepository(db);
    });

    tearDown(() => db.close());

    Future<void> seed(String json) => WordSeedLoader(
          itemRepository: items,
          loadSeedJson: () async => json,
        ).seed();

    Future<List<Item>> words() async =>
        (await items.getItems()).where((i) => i.isWord).toList();

    test('the whole bundled list is added beside the kana', () async {
      await KanaSeedLoader(
        itemRepository: items,
        loadSeedJson: () async => kanaJson,
      ).seed();
      final info = await WordSeedLoader(
        itemRepository: items,
        loadSeedJson: () async => bundled,
      ).seed();

      final all = await items.getItems();
      expect(all.where((i) => i.isKana), hasLength(211));
      expect(all.where((i) => i.isWord), hasLength(info.keys.length));
      expect(all.where((i) => i.isWord && i.isIntroduced), isEmpty);
      // Kana first, then words in the list's order.
      expect(all.take(211).every((i) => i.isKana), isTrue);
      expect(await db.select(db.mnemonics).get(), hasLength(211));
    });

    test('seeding twice changes nothing', () async {
      await seed(bundled);
      final before = await db.select(db.items).get();
      await seed(bundled);
      final after = await db.select(db.items).get();
      expect(after.length, before.length);
      expect(after.map((r) => (r.id, r.itemKey, r.payload, r.sortOrder)),
          before.map((r) => (r.id, r.itemKey, r.payload, r.sortOrder)));
    });

    test('a corrected meaning reaches a learned word without touching it',
        () async {
      await seed(listOf([entry('1', 'あ', meanings: ['old'])]));
      final word = (await words()).single;
      final learnedAt = DateTime(2026, 1, 5, 8);
      await items.markIntroduced([word.id], learnedAt);
      final cards = DriftCardRepository(db);
      await cards.createCard(
        itemId: word.id,
        promptType: PromptType.wordToMeaningChoice,
        scheduling: SchedulingState(
          phase: CardPhase.learning,
          step: 0,
          due: learnedAt,
        ),
        createdAt: learnedAt,
      );

      await seed(listOf([entry('1', 'あ', meanings: ['new'], order: 7)]));

      final updated = (await words()).single;
      expect(updated.id, word.id);
      expect(updated.word.meanings, ['new']);
      expect(updated.sortOrder, WordSeedLoader.sortOrderBase + 7);
      expect(updated.introducedAt, learnedAt);
      expect(await cards.getCards(), hasLength(1));
    });

    test('a new word is added, not yet introduced', () async {
      await seed(listOf([entry('1', 'あ')]));
      await seed(listOf([entry('1', 'あ'), entry('2', 'い', order: 2)]));
      final all = await words();
      expect(all.map((w) => w.key), ['word:1', 'word:2']);
      expect(all.last.isIntroduced, isFalse);
    });

    test('a word dropped from the list stays', () async {
      await seed(listOf([entry('1', 'あ'), entry('2', 'い', order: 2)]));
      final info = await WordSeedLoader(
        itemRepository: items,
        loadSeedJson: () async => listOf([entry('1', 'あ')]),
      ).seed();
      expect(await words(), hasLength(2));
      expect(info.keys, {'word:1'});
    });
  });
}
