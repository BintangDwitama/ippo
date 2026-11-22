import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/words/build_words.dart' as build_words;
import '../../tool/words/src/beginner_list.dart';
import '../../tool/words/src/preview.dart';
import '../../tool/words/src/word_builder.dart';
import '../../tool/words/src/word_file.dart';
import 'fixtures.dart';

void main() {
  final splitter = realSplitter();
  const wordFile = WordFile();

  /// A valid list of [count] made-up words: every pair of basic hiragana.
  BuildResult manyWords({int count = 400}) {
    final basic = splitter.all
        .where((k) => k.script == 'hiragana' && k.group == 'basic')
        .toList();
    final list = <BeginnerEntry>[];
    final entries = <Map<String, Object?>>[];
    for (final a in basic) {
      for (final b in basic) {
        if (list.length == count) break;
        final id = '${1000 + list.length}';
        final reading = a.character + b.character;
        list.add(listed(id, reading));
        entries.add(entry(id, kana: [reading], senses: [sense(['word $id'])]));
      }
    }
    return WordBuilder(splitter: splitter)
        .build(beginnerList: list, dictionary: dictionaryOf(entries));
  }

  group('the self-checks', () {
    test('a valid list passes', () {
      wordFile.check(manyWords().words, splitter: splitter);
    });

    void expectRefused(List<Word> words) {
      expect(
        () => wordFile.check(words, splitter: splitter),
        throwsA(isA<WordListCheckException>()),
      );
    }

    test('a list far too short is refused', () {
      expectRefused(manyWords(count: 20).words);
    });

    test('a repeated word is refused', () {
      final words = manyWords().words;
      expectRefused([...words.take(399), words.first]);
    });

    test('a gap in the order is refused', () {
      final words = manyWords().words;
      expectRefused([words[0], ...words.skip(2)]);
    });

    test('a meaning with parentheses or no meaning is refused', () {
      final words = manyWords().words;
      expectRefused([
        words.first.copyWith(meanings: ['dog (animal)']),
        ...words.skip(1),
      ]);
      expectRefused([words.first.copyWith(meanings: []), ...words.skip(1)]);
    });
  });

  group('the file text', () {
    test('identical input gives identical text', () {
      String text() => wordFile.encode(
            manyWords().words,
            dictionaryDate: '2026-01-01',
            dictionaryVersion: '3.6.2',
          );
      expect(text(), text());
    });

    test('it is JSON with a header and one word per line', () {
      final words = manyWords().words;
      final text = wordFile.encode(
        words,
        dictionaryDate: '2026-01-01',
        dictionaryVersion: '3.6.2',
      );
      final json = jsonDecode(text) as Map<String, Object?>;
      expect(json['format'], 'ippo-words');
      expect(json['formatVersion'], 1);
      expect(json['dictionaryDate'], '2026-01-01');
      expect(json['licence'], 'CC BY-SA 4.0');
      expect(json['sources'], hasLength(2));
      expect(json['words'], hasLength(words.length));
      expect(
        text.split('\n').where((l) => l.startsWith('    {"id"')),
        hasLength(words.length),
      );
    });

    test('the preview lists every word and what was left out', () {
      final result = WordBuilder(splitter: splitter).build(
        beginnerList: [listed('1', 'いえ'), listed('2', 'フォーク')],
        dictionary: dictionaryOf([
          entry('1', kana: ['いえ'], senses: [sense(['house'])]),
          entry('2', kana: ['フォーク'], senses: [sense(['fork'])]),
        ]),
      );
      final preview = buildPreview(
        result,
        splitter: splitter,
        dictionaryDate: '2026-01-01',
      );
      expect(preview, contains('| 1 | いえ |  | house ? | noun | N5 |'));
      expect(preview, contains('Left out: needs a kana'));
      expect(preview, contains('フォーク'));
    });
  });

  test('a build that fails leaves the existing files alone', () async {
    final dir = Directory.systemTemp.createTempSync('ippo_words_test');
    addTearDown(() => dir.deleteSync(recursive: true));
    final dictionary = File('${dir.path}/dictionary.json')
      ..writeAsStringSync(jsonEncode(dictionaryJson([])));
    final existing = File('${dir.path}/words.json')
      ..writeAsStringSync('existing');

    // An empty dictionary matches nothing, so the build cannot succeed:
    // every check runs before the first file is written.
    await build_words.main(
      ['--dictionary', dictionary.path, '--out', dir.path],
    );
    final failed = exitCode;
    exitCode = 0;

    expect(failed, 1);
    expect(existing.readAsStringSync(), 'existing');
    expect(File('${dir.path}/preview.md').existsSync(), isFalse);
  });

  group('the committed word list', () {
    final text = File('data/words/words.json').readAsStringSync();
    final json = jsonDecode(text) as Map<String, Object?>;
    final words = (json['words']! as List<Object?>).cast<Map<String, Object?>>();
    Map<String, Object?> wordRead(String reading) =>
        words.singleWhere((w) => w['reading'] == reading);

    test('has the expected header', () {
      expect(json['format'], WordFile.formatName);
      expect(json['formatVersion'], WordFile.formatVersion);
      expect(json['dictionaryDate'], matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
      expect(json['licence'], 'CC BY-SA 4.0');
    });

    test('holds a plausible number of words in order', () {
      expect(words.length, inInclusiveRange(1000, 1500));
      for (var i = 0; i < words.length; i++) {
        expect(words[i]['order'], i + 1);
      }
    });

    test('every word is unique, readable and has clean meanings', () {
      final taught = {for (final k in splitter.all) k.key};
      final ids = <Object?>{};
      final readings = <Object?>{};
      for (final word in words) {
        final reading = word['reading']! as String;
        expect(ids.add(word['id']), isTrue, reason: reading);
        expect(readings.add(reading), isTrue, reason: reading);
        expect([5, 4], contains(word['level']), reason: reading);

        final meanings = (word['meanings']! as List<Object?>).cast<String>();
        expect(meanings.length, inInclusiveRange(1, 3), reason: reading);
        for (final meaning in meanings) {
          expect(meaning.trim(), isNotEmpty, reason: reading);
          expect(meaning, isNot(contains('(')), reason: reading);
        }

        final kana = (word['kana']! as List<Object?>).cast<String>();
        expect(taught.containsAll(kana), isTrue, reason: reading);
        expect(
          kana.toSet(),
          {for (final k in splitter.split(reading)!) k.key},
          reason: reading,
        );
      }
    });

    test('level 5 words all come before level 4 words', () {
      final levels = [for (final w in words) w['level']! as int];
      expect(levels.lastIndexOf(5), lessThan(levels.indexOf(4)));
    });

    test('some words become readable after the very first row', () {
      const firstRow = {
        'hiragana:a',
        'hiragana:i',
        'hiragana:u',
        'hiragana:e',
        'hiragana:o',
      };
      final early = words.where(
        (w) => firstRow.containsAll((w['kana']! as List<Object?>).cast<String>()),
      );
      expect(early.length, greaterThanOrEqualTo(8));
    });

    test('known words read as a beginner expects', () {
      expect(wordRead('いぬ')['meanings'], ['dog']);
      expect(wordRead('いぬ')['written'], '犬');
      expect(wordRead('おいしい')['meanings'], contains('delicious'));
      expect(wordRead('コップ')['id'], '1050390');
      expect(wordRead('たべる')['partOfSpeech'], 'verb');
    });

    test('every correction names a row of the beginner list', () {
      final listIds = {
        for (final level in ['n5', 'n4'])
          for (final e in parseBeginnerList(
            File('data/words/sources/jlpt_$level.csv').readAsStringSync(),
            level: 5,
          ))
            e.id,
      };
      final overrides = jsonDecode(
        File('data/words/overrides.json').readAsStringSync(),
      ) as Map<String, Object?>;
      expect(listIds.containsAll(overrides.keys), isTrue);
    });

    test('the preview is for the same list', () {
      final preview = File('data/words/preview.md').readAsStringSync();
      expect(preview, contains('${words.length} words.'));
      expect(preview, contains(json['dictionaryDate']! as String));
    });
  });
}
