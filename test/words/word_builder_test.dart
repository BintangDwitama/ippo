import 'package:flutter_test/flutter_test.dart';

import '../../tool/words/src/beginner_list.dart';
import '../../tool/words/src/dictionary.dart';
import '../../tool/words/src/word_builder.dart';
import 'fixtures.dart';

void main() {
  final builder = WordBuilder(splitter: realSplitter());

  BuildResult build(
    List<BeginnerEntry> list,
    List<Map<String, Object?>> entries, {
    Map<String, WordOverride> overrides = const {},
  }) {
    return builder.build(
      beginnerList: list,
      dictionary: dictionaryOf(entries),
      overrides: overrides,
    );
  }

  final dog = entry(
    '10',
    kana: ['いぬ'],
    kanji: ['犬'],
    senses: [
      sense(['dog (Canis lupus familiaris)', 'canine']),
      sense(['snoop', 'spy'], misc: ['derog']),
    ],
  );

  group('the dictionary file', () {
    test('a file of another major version is refused', () {
      expect(
        () => Dictionary.fromJson(
          dictionaryJson([dog], version: '4.0.0'),
          wantedIds: {'10'},
        ),
        throwsFormatException,
      );
    });

    test('only the wanted entries are kept, with the file date', () {
      final dictionary = Dictionary.fromJson(
        dictionaryJson([dog, entry('11', kana: ['ねこ'], senses: [])]),
        wantedIds: {'10'},
      );
      expect(dictionary.entries.keys, ['10']);
      expect(dictionary.date, '2026-01-01');
    });
  });

  group('matching and selection', () {
    test('a listed word found in the dictionary becomes a word', () {
      final result = build(
        [listed('10', 'いぬ', kanji: '犬', definition: 'dog')],
        [dog],
      );
      final word = result.words.single;
      expect(word.id, '10');
      expect(word.reading, 'いぬ');
      expect(word.written, '犬');
      expect(word.level, 5);
      expect(word.order, 1);
      expect(word.kana.map((k) => k.key), ['hiragana:i', 'hiragana:nu']);
      expect(result.leftOut, isEmpty);
    });

    test('a listed word missing from the dictionary is reported', () {
      final result = build([listed('99', 'いぬ')], [dog]);
      expect(result.words, isEmpty);
      expect(result.leftOut.single.reason, LeftOutReason.notInDictionary);
    });

    test('a word needing an untaught kana is left out, naming it', () {
      final result = build(
        [listed('20', 'フォーク')],
        [
          entry('20', kana: ['フォーク'], senses: [sense(['fork'])]),
        ],
      );
      expect(result.words, isEmpty);
      expect(result.leftOut.single.reason, LeftOutReason.unreadable);
      expect(result.leftOut.single.detail, 'ォ');
    });

    test('a word whose every sense is restricted is left out', () {
      for (final tag in WordBuilder.restrictedTags) {
        final result = build(
          [listed('30', 'かんごふ')],
          [
            entry(
              '30',
              kana: ['かんごふ'],
              senses: [sense(['nurse'], misc: [tag])],
            ),
          ],
        );
        expect(result.words, isEmpty, reason: tag);
        expect(result.leftOut.single.reason, LeftOutReason.restrictedSense);
      }
    });

    test('a restricted sense is skipped when another sense is fine', () {
      final result = build([listed('10', 'いぬ', kanji: '犬')], [dog]);
      expect(result.words.single.meanings, ['canine']);
    });

    test('the same entry listed twice gives one word, at the first level', () {
      final result = build(
        [
          listed('10', 'いぬ', kanji: '犬', definition: 'dog'),
          listed('10', 'いぬ', kanji: '犬', definition: 'dog', level: 4),
        ],
        [dog],
      );
      expect(result.words.single.level, 5);
    });
  });

  group('one word per reading', () {
    Map<String, Object?> ame(String id, String kanji, String gloss) =>
        entry(id, kana: ['あめ'], kanji: [kanji], senses: [sense([gloss])]);

    test('the lower level wins and the other is set aside', () {
      final result = build(
        [
          listed('41', 'あめ', kanji: '飴', definition: 'candy', level: 4),
          listed('42', 'あめ', kanji: '雨', definition: 'rain'),
        ],
        [ame('41', '飴', 'candy'), ame('42', '雨', 'rain')],
      );
      expect(result.words.single.written, '雨');
      final aside = result.leftOut.single;
      expect(aside.reason, LeftOutReason.sameReading);
      expect(aside.entry.kanji, '飴');
      expect(aside.detail, contains('雨'));
    });

    test('at the same level the common reading wins', () {
      final result = build(
        [
          listed('41', 'あめ', kanji: '飴'),
          listed('42', 'あめ', kanji: '雨'),
        ],
        [
          entry(
            '41',
            kana: [
              {'text': 'あめ', 'common': false, 'tags': <String>[]},
            ],
            kanji: ['飴'],
            senses: [sense(['candy'])],
          ),
          ame('42', '雨', 'rain'),
        ],
      );
      expect(result.words.single.written, '雨');
    });

    test('otherwise the smaller id wins', () {
      final result = build(
        [
          listed('42', 'あめ', kanji: '雨'),
          listed('41', 'あめ', kanji: '飴'),
        ],
        [ame('41', '飴', 'candy'), ame('42', '雨', 'rain')],
      );
      expect(result.words.single.id, '41');
    });
  });

  group('meanings', () {
    final oishii = entry(
      '50',
      kana: ['おいしい'],
      kanji: ['美味しい'],
      senses: [
        sense(
          ['good (tasting)', 'nice', 'delicious', 'tasty'],
          partOfSpeech: ['adj-i'],
        ),
        sense(['attractive (offer)'], partOfSpeech: ['adj-i']),
      ],
    );

    test('the dictionary wording of what the list names is preferred', () {
      final result = build(
        [listed('50', 'おいしい', definition: 'Delicious, a tasty')],
        [oishii],
      );
      final word = result.words.single;
      expect(word.meanings, ['delicious', 'tasty']);
      expect(word.meaningSource, MeaningSource.endorsed);
    });

    test('with no match the first sense is used, plain glosses first', () {
      final result = build(
        [listed('50', 'おいしい', definition: 'yummy')],
        [oishii],
      );
      final word = result.words.single;
      expect(word.meanings, ['nice', 'delicious']);
      expect(word.meaningSource, MeaningSource.firstSense);
    });

    test('parentheses are cut only when every gloss has them', () {
      final result = build(
        [listed('51', 'みそ')],
        [
          entry(
            '51',
            kana: ['みそ'],
            senses: [sense(['miso (fermented paste)', 'paste (soy)'])],
          ),
        ],
      );
      expect(result.words.single.meanings, ['miso', 'paste']);
    });

    test('a sense for another spelling is not used', () {
      final result = build(
        [listed('52', 'あう', kanji: '会う')],
        [
          entry(
            '52',
            kana: ['あう'],
            kanji: ['会う', '遭う'],
            senses: [
              sense(['to have an accident'], appliesToKanji: ['遭う']),
              sense(['to meet'], partOfSpeech: ['v5u']),
            ],
          ),
        ],
      );
      expect(result.words.single.meanings, ['to meet']);
      expect(result.words.single.partOfSpeech, 'verb');
    });

    test('cleaning a gloss', () {
      expect(cleanMeaning('dog (Canis (lupus) familiaris)'), 'dog');
      expect(cleanMeaning('to  meet'), 'to meet');
      expect(cleanMeaning('(only this)'), '');
    });

    test('part of speech in plain words', () {
      expect(partOfSpeechOf(['adj-i']), 'i-adjective');
      expect(partOfSpeechOf(['adj-na', 'n']), 'na-adjective');
      expect(partOfSpeechOf(['n', 'vs']), 'noun');
      expect(partOfSpeechOf(['vs', 'n']), 'noun');
      expect(partOfSpeechOf(['v1', 'vt']), 'verb');
      expect(partOfSpeechOf(['adv']), 'adverb');
      expect(partOfSpeechOf(['pn']), 'pronoun');
      expect(partOfSpeechOf(['exp']), 'expression');
      expect(partOfSpeechOf(['int']), 'other');
    });
  });

  group('the written form', () {
    final glass = entry(
      '60',
      kana: ['コップ'],
      kanji: [
        {'text': '洋杯', 'common': false, 'tags': ['rK']},
      ],
      senses: [sense(['glass'])],
    );

    test('a word the list gives in kana has none', () {
      final result = build([listed('10', 'いぬ')], [dog]);
      expect(result.words.single.written, isNull);
    });

    test('a rare spelling is not shown', () {
      final result = build([listed('60', 'コップ', kanji: '洋杯')], [glass]);
      expect(result.words.single.written, isNull);
    });

    test('a spelling the dictionary lacks falls back to its common one', () {
      final result = build([listed('10', 'いぬ', kanji: '狗')], [dog]);
      expect(result.words.single.written, '犬');
    });
  });

  group('corrections', () {
    final list = [listed('10', 'いぬ', kanji: '犬', definition: 'dog')];

    test('meanings and the written form can be replaced', () {
      final result = build(
        list,
        [dog],
        overrides: {
          '10': WordOverride.fromJson({
            'meanings': ['dog'],
            'written': null,
            'note': 'ignored',
          }),
        },
      );
      final word = result.words.single;
      expect(word.meanings, ['dog']);
      expect(word.written, isNull);
      expect(word.meaningSource, MeaningSource.corrected);
    });

    test('a word can be excluded', () {
      final result = build(
        list,
        [dog],
        overrides: {'10': const WordOverride(exclude: true)},
      );
      expect(result.words, isEmpty);
      expect(result.leftOut.single.reason, LeftOutReason.excludedByOverride);
    });

    test('a row can be pointed at another dictionary entry', () {
      const overrides = {'10': WordOverride(useEntry: '11')};
      expect(WordBuilder.wantedIds(list, overrides), {'10', '11'});
      final result = build(
        list,
        [
          dog,
          entry('11', kana: ['いぬ'], kanji: ['犬'], senses: [sense(['dog'])]),
        ],
        overrides: overrides,
      );
      expect(result.words.single.id, '11');
      expect(result.words.single.meanings, ['dog']);
    });

    test('a correction that matches nothing stops the build', () {
      expect(
        () => build(
          list,
          [dog],
          overrides: {'77': const WordOverride(exclude: true)},
        ),
        throwsA(isA<StaleOverrideException>()),
      );
    });

    test('an unknown field is refused', () {
      expect(
        () => WordOverride.fromJson({'meaning': 'dog'}),
        throwsFormatException,
      );
    });
  });

  group('order', () {
    Map<String, Object?> plain(String id, String reading) =>
        entry(id, kana: [reading], senses: [sense(['x$id'])]);

    test('level 5 first, then by the last kana needed, then by length', () {
      final result = build(
        [
          listed('1', 'かお'),
          listed('2', 'あい', level: 4),
          listed('3', 'いえ'),
          listed('4', 'あおい'),
          listed('5', 'うえ'),
        ],
        [
          plain('1', 'かお'),
          plain('2', 'あい'),
          plain('3', 'いえ'),
          plain('4', 'あおい'),
          plain('5', 'うえ'),
        ],
      );
      expect(
        result.words.map((w) => w.reading),
        ['いえ', 'うえ', 'あおい', 'かお', 'あい'],
      );
      expect(result.words.map((w) => w.order), [1, 2, 3, 4, 5]);
    });
  });
}
