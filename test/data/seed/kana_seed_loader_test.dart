import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ippo/data/seed/kana_seed_loader.dart';
import 'package:ippo/domain/models/item.dart';
import 'package:ippo/domain/models/seed_item.dart';

import '../../fakes/fake_repositories.dart';
import '../../support/seed_items.dart';

void main() {
  Future<String> loadRealSeed() =>
      File(KanaSeedLoader.assetPath).readAsString();

  KanaPayload kana(SeedItem seed) => seed.payload as KanaPayload;

  group('the bundled seed', () {
    final seeds = realSeed();
    List<SeedItem> of(KanaScript script, [KanaGroup? group]) => [
      for (final seed in seeds)
        if (kana(seed).script == script &&
            (group == null || kana(seed).group == group))
          seed,
    ];

    test('has 46 basic, 25 voiced and 33 combination kana per script', () {
      expect(seeds, hasLength(211));
      for (final script in KanaScript.values) {
        expect(of(script, KanaGroup.basic), hasLength(46));
        expect(of(script, KanaGroup.voiced), hasLength(25));
        expect(of(script, KanaGroup.combination), hasLength(33));
      }
      expect(of(KanaScript.hiragana, KanaGroup.mark), hasLength(1));
      expect(of(KanaScript.katakana, KanaGroup.mark), hasLength(2));
    });

    test('gives every kana a unique key, character and position', () {
      expect(seeds.map((s) => s.key).toSet(), hasLength(211));
      expect(seeds.map((s) => s.sortOrder).toSet(), hasLength(211));
      expect(seeds.map((s) => kana(s).character).toSet(), hasLength(211));
    });

    test('gives every kana a reading, a row and a mnemonic', () {
      for (final seed in seeds) {
        expect(kana(seed).romaji, isNotEmpty, reason: seed.key);
        expect(kana(seed).row, isNotEmpty, reason: seed.key);
        expect(seed.defaultMnemonic.trim(), isNotEmpty, reason: seed.key);
      }
    });

    test('keeps every key of the original 92 kana', () {
      final original =
          jsonDecode(File('test/fixtures/kana_seed_v1.json').readAsStringSync())
              as List<Object?>;
      final keys = seeds.map((s) => s.key).toSet();

      expect(original, hasLength(92));
      for (final entry in original.cast<Map<String, Object?>>()) {
        expect(keys, contains('${entry['script']}:${entry['romaji']}'));
      }
    });

    test('keeps the original mnemonics of the basic kana', () {
      final original =
          jsonDecode(File('test/fixtures/kana_seed_v1.json').readAsStringSync())
              as List<Object?>;
      final byKey = {for (final seed in seeds) seed.key: seed};

      for (final entry in original.cast<Map<String, Object?>>()) {
        final seed = byKey['${entry['script']}:${entry['romaji']}']!;
        expect(seed.defaultMnemonic, entry['mnemonic']);
        expect(kana(seed).character, entry['character']);
        expect(kana(seed).group, KanaGroup.basic);
      }
    });

    test('orders the path: each script basic, voiced, then combination, '
        'hiragana first', () {
      final ordered = [...seeds]
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      final stages = <(KanaScript, KanaGroup)>[];
      for (final seed in ordered) {
        final stage = (kana(seed).script, kana(seed).group);
        if (stages.isEmpty || stages.last != stage) stages.add(stage);
      }

      expect(stages, [
        (KanaScript.hiragana, KanaGroup.basic),
        (KanaScript.hiragana, KanaGroup.voiced),
        (KanaScript.hiragana, KanaGroup.combination),
        (KanaScript.hiragana, KanaGroup.mark),
        (KanaScript.katakana, KanaGroup.basic),
        (KanaScript.katakana, KanaGroup.voiced),
        (KanaScript.katakana, KanaGroup.combination),
        (KanaScript.katakana, KanaGroup.mark),
      ]);
      expect(kana(ordered.first).character, 'あ');
    });

    test('keeps each row together and no longer than five', () {
      final ordered = [...seeds]
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      final sizes = <(KanaScript, KanaGroup, String), int>{};
      (KanaScript, KanaGroup, String)? previous;
      for (final seed in ordered) {
        final row = (kana(seed).script, kana(seed).group, kana(seed).row);
        if (row != previous) {
          expect(
            sizes.containsKey(row),
            isFalse,
            reason: 'row ${row.$3} is split in the teaching order',
          );
        }
        sizes[row] = (sizes[row] ?? 0) + 1;
        previous = row;
      }

      expect(sizes.values.every((size) => size <= 5), isTrue);
      // Combination rows are always ya, yu, yo.
      for (final entry in sizes.entries) {
        if (entry.key.$2 == KanaGroup.combination) expect(entry.value, 3);
      }
    });

    test('keeps the two kana that share a reading apart', () {
      final hiragana = of(KanaScript.hiragana);
      SeedItem by(String character) =>
          hiragana.firstWhere((s) => kana(s).character == character);

      expect(kana(by('じ')).romaji, 'ji');
      expect(kana(by('ぢ')).romaji, 'ji');
      expect(by('じ').key, 'hiragana:ji');
      expect(by('ぢ').key, 'hiragana:di');
      expect(kana(by('ぢ')).acceptedRomaji, containsAll(['ji', 'di']));
      expect(by('ず').key, 'hiragana:zu');
      expect(by('づ').key, 'hiragana:du');
      expect(kana(by('づ')).acceptedRomaji, containsAll(['zu', 'du']));
    });

    test('links partners through their family', () {
      final hiragana = of(KanaScript.hiragana);
      List<String> family(String reading) => [
        for (final seed in hiragana)
          if (kana(seed).family == reading) kana(seed).character,
      ];

      expect(family('ka'), ['か', 'が']);
      expect(family('ha'), ['は', 'ば', 'ぱ']);
      expect(family('shi'), ['し', 'じ']);
      expect(family('kya'), ['きゃ', 'ぎゃ']);
      expect(family('hyo'), ['ひょ', 'びょ', 'ぴょ']);
      // Every family is anchored by a kana that reads as the family name.
      final readings = {
        for (final seed in seeds) (kana(seed).script, kana(seed).romaji),
      };
      for (final seed in seeds) {
        expect(
          readings,
          contains((kana(seed).script, kana(seed).family)),
          reason: seed.key,
        );
      }
    });

    test('lists look-alikes that exist in the same script, both ways', () {
      for (final seed in seeds) {
        for (final character in kana(seed).lookalikes) {
          final other = of(
            kana(seed).script,
          ).where((s) => kana(s).character == character);
          expect(other, hasLength(1), reason: '${seed.key} -> $character');
          expect(
            kana(other.single).lookalikes,
            contains(kana(seed).character),
            reason: '$character should list ${kana(seed).character}',
          );
        }
      }
      final nu = of(
        KanaScript.hiragana,
      ).firstWhere((s) => kana(s).character == 'ぬ');
      expect(kana(nu).lookalikes, contains('め'));
    });

    test('states the rule in the mnemonic of voiced and combination kana', () {
      final hiragana = of(KanaScript.hiragana);
      String mnemonic(String character) => hiragana
          .firstWhere((s) => kana(s).character == character)
          .defaultMnemonic;

      expect(mnemonic('が'), allOf(contains('か'), contains('"ga"')));
      expect(mnemonic('ぱ'), allOf(contains('は'), contains('circle')));
      expect(mnemonic('きゃ'), allOf(contains('き'), contains('や')));
      expect(mnemonic('ぢ'), contains('じ'));
      for (final seed in seeds) {
        if (kana(seed).group == KanaGroup.basic || kana(seed).isMark) {
          continue;
        }
        expect(
          seed.defaultMnemonic,
          contains('"${kana(seed).romaji}"'),
          reason: seed.key,
        );
      }
    });
  });

  test('seeding twice yields exactly 211 items', () async {
    final items = FakeItemRepository();
    final loader = KanaSeedLoader(
      itemRepository: items,
      loadSeedJson: loadRealSeed,
    );

    await loader.seed();
    await loader.seed();

    expect(await items.getItems(), hasLength(211));
  });

  group('the marks', () {
    final marks = [
      for (final seed in realSeed())
        if ((seed.payload as KanaPayload).isMark) seed,
    ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    KanaPayload markOf(String character) => marks
        .map((s) => s.payload as KanaPayload)
        .firstWhere((k) => k.character == character);

    test('are the small tsu of each script and the long mark', () {
      expect(marks.map((s) => (s.payload as KanaPayload).character), [
        'っ',
        'ッ',
        'ー',
      ]);
      expect(marks.map((s) => s.key), [
        'hiragana:sokuon',
        'katakana:sokuon',
        'katakana:choon',
      ]);
      expect(markOf('っ').script, KanaScript.hiragana);
      expect(markOf('ッ').script, KanaScript.katakana);
      expect(markOf('ー').script, KanaScript.katakana);
    });

    test('come after every other kana of their script', () {
      final seeds = realSeed();
      for (final mark in marks) {
        final script = (mark.payload as KanaPayload).script;
        final others = seeds.where((s) {
          final kana = s.payload as KanaPayload;
          return kana.script == script && !kana.isMark;
        });
        expect(
          others.every((s) => s.sortOrder < mark.sortOrder),
          isTrue,
          reason: mark.key,
        );
      }
      // And hiragana's mark still comes before any katakana.
      final firstKatakana = seeds
          .where(
            (s) => (s.payload as KanaPayload).script == KanaScript.katakana,
          )
          .map((s) => s.sortOrder)
          .reduce((a, b) => a < b ? a : b);
      expect(marks.first.sortOrder, lessThan(firstKatakana));
    });

    test('have a name in place of a reading', () {
      expect(markOf('っ').romaji, 'small tsu');
      expect(markOf('ッ').romaji, 'small tsu');
      expect(markOf('ー').romaji, 'long mark');
    });

    test('are spoken as a pair that differs only by the mark', () {
      expect(markOf('っ').spoken, 'きて、きって');
      expect(markOf('ッ').spoken, 'カト、カット');
      expect(markOf('ー').spoken, 'ビル、ビール');
      for (final mark in marks) {
        final kana = mark.payload as KanaPayload;
        final pair = kana.spoken.split('、');
        expect(pair, hasLength(2), reason: mark.key);
        expect(
          pair[1].replaceAll(kana.character, ''),
          pair[0],
          reason: mark.key,
        );
      }
    });

    test('explain their effect in the mnemonic, with the same example', () {
      for (final mark in marks) {
        final kana = mark.payload as KanaPayload;
        for (final word in kana.spoken.split('、')) {
          expect(mark.defaultMnemonic, contains(word), reason: mark.key);
        }
        expect(mark.defaultMnemonic, contains('no sound of its own'));
      }
      expect(marks.first.defaultMnemonic, contains('doubles the consonant'));
      expect(marks.last.defaultMnemonic, contains('twice as long'));
    });

    test('ordinary kana are spoken as their character', () {
      final ka = realSeed()
          .map((s) => s.payload as KanaPayload)
          .firstWhere((k) => k.character == 'か');

      expect(ka.sample, isNull);
      expect(ka.spoken, 'か');
      expect(ka.isMark, isFalse);
    });
  });

  group('parse', () {
    Map<String, Object?> entry() => {
      'script': 'hiragana',
      'character': 'が',
      'romaji': 'ga',
      'alt': <String>[],
      'group': 'voiced',
      'row': 'g',
      'family': 'ka',
      'lookalikes': <String>[],
      'order': 100,
      'mnemonic': 'ka with marks',
    };
    SeedItem parseOne(Map<String, Object?> e) =>
        KanaSeedLoader.parse(jsonEncode([e])).single;

    test('reads every field of an entry', () {
      final seed = parseOne(entry());

      expect(seed.key, 'hiragana:ga');
      expect(seed.sortOrder, 100);
      expect(seed.defaultMnemonic, 'ka with marks');
      expect(kana(seed).group, KanaGroup.voiced);
      expect(kana(seed).row, 'g');
      expect(kana(seed).family, 'ka');
    });

    test('uses a stated key in place of script and reading', () {
      final seed = parseOne(entry()..['key'] = 'hiragana:special');

      expect(seed.key, 'hiragana:special');
    });

    test('rejects malformed seed data', () {
      expect(() => KanaSeedLoader.parse('{}'), throwsFormatException);
      expect(
        () => KanaSeedLoader.parse('[{"script": "hiragana"}]'),
        throwsFormatException,
      );
      expect(() => parseOne(entry()..remove('group')), throwsFormatException);
      expect(() => parseOne(entry()..remove('row')), throwsFormatException);
    });

    test('rejects an unknown group or script', () {
      expect(
        () => parseOne(entry()..['group'] = 'whispered'),
        throwsFormatException,
      );
      expect(
        () => parseOne(entry()..['script'] = 'romaji'),
        throwsFormatException,
      );
    });
  });
}
