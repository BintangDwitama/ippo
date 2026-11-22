import 'package:flutter_test/flutter_test.dart';

import '../../tool/words/src/beginner_list.dart';
import 'fixtures.dart';

void main() {
  final splitter = realSplitter();
  List<String>? keys(String reading) =>
      splitter.split(reading)?.map((k) => k.key).toList();

  group('splitting a reading', () {
    test('plain kana, one per character', () {
      expect(keys('あおい'), ['hiragana:a', 'hiragana:o', 'hiragana:i']);
    });

    test('a combination kana is one kana, not two', () {
      expect(keys('きょう'), ['hiragana:kyo', 'hiragana:u']);
      expect(keys('シャツ'), ['katakana:sha', 'katakana:tsu']);
    });

    test('the small tsu and the long mark are kana of their own', () {
      expect(
        keys('きって'),
        ['hiragana:ki', 'hiragana:sokuon', 'hiragana:te'],
      );
      expect(
        keys('コーヒー'),
        ['katakana:ko', 'katakana:choon', 'katakana:hi', 'katakana:choon'],
      );
    });

    test('a reading with an untaught character cannot be split', () {
      String? unknown;
      final result =
          splitter.split('フォーク', onUnknown: (c) => unknown = c);
      expect(result, isNull);
      expect(unknown, 'ォ');
    });

    test('kanji and an empty reading cannot be split', () {
      expect(keys('犬'), isNull);
      expect(keys(''), isNull);
    });
  });

  group('reading the beginner list', () {
    test('rows become entries at the given level', () {
      final entries = parseBeginnerList(
        'jmdict_seq,kana,kanji,waller_definition\n'
        '1258330,いぬ,犬,dog\n'
        '1050390,コップ,,"a glass, a ""cup"""\n',
        level: 5,
      );
      expect(entries, hasLength(2));
      expect(entries[0].id, '1258330');
      expect(entries[0].kanji, '犬');
      expect(entries[1].kanji, isEmpty);
      expect(entries[1].definition, 'a glass, a "cup"');
      expect(entries[1].level, 5);
    });

    test('an unexpected header or a short row is refused', () {
      expect(
        () => parseBeginnerList('id,kana\n1,あ\n', level: 5),
        throwsFormatException,
      );
      expect(
        () => parseBeginnerList(
          'jmdict_seq,kana,kanji,waller_definition\n1,あ\n',
          level: 5,
        ),
        throwsFormatException,
      );
    });
  });
}
