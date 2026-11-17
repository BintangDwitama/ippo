import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ippo/data/seed/kana_seed_loader.dart';
import 'package:ippo/domain/models/item.dart';

import '../../fakes/fake_repositories.dart';

void main() {
  Future<String> loadRealSeed() =>
      File(KanaSeedLoader.assetPath).readAsString();

  test('the bundled seed has 46 hiragana and 46 katakana', () async {
    final seeds = KanaSeedLoader.parse(await loadRealSeed());
    final hiragana =
        seeds.where((s) => (s.payload as KanaPayload).script == KanaScript.hiragana);
    final katakana =
        seeds.where((s) => (s.payload as KanaPayload).script == KanaScript.katakana);

    expect(hiragana, hasLength(46));
    expect(katakana, hasLength(46));
  });

  test('every seeded kana is unique and complete', () async {
    final seeds = KanaSeedLoader.parse(await loadRealSeed());

    expect(seeds.map((s) => s.key).toSet(), hasLength(92));
    expect(seeds.map((s) => s.sortOrder).toSet(), hasLength(92));
    expect(
      seeds.map((s) => (s.payload as KanaPayload).character).toSet(),
      hasLength(92),
    );
    for (final seed in seeds) {
      final kana = seed.payload as KanaPayload;
      expect(kana.romaji, isNotEmpty);
      expect(seed.defaultMnemonic.trim(), isNotEmpty, reason: seed.key);
    }
  });

  test('all hiragana come before all katakana in teaching order', () async {
    final seeds = KanaSeedLoader.parse(await loadRealSeed())
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final scripts = seeds.map((s) => (s.payload as KanaPayload).script).toList();

    expect(scripts.take(46).toSet(), {KanaScript.hiragana});
    expect(scripts.skip(46).toSet(), {KanaScript.katakana});
    expect((seeds.first.payload as KanaPayload).character, 'あ');
  });

  test('seeding twice yields exactly 92 items', () async {
    final items = FakeItemRepository();
    final loader =
        KanaSeedLoader(itemRepository: items, loadSeedJson: loadRealSeed);

    await loader.seed();
    await loader.seed();

    expect(await items.getItems(), hasLength(92));
  });

  test('rejects malformed seed data', () {
    expect(() => KanaSeedLoader.parse('{}'), throwsFormatException);
    expect(
      () => KanaSeedLoader.parse('[{"script": "hiragana"}]'),
      throwsFormatException,
    );
  });
}
