import 'dart:io';

import 'package:ippo/data/seed/kana_seed_loader.dart';
import 'package:ippo/domain/models/item.dart';
import 'package:ippo/domain/models/seed_item.dart';

/// The app's real kana seed, parsed.
List<SeedItem> realSeed() {
  return KanaSeedLoader.parse(
    File(KanaSeedLoader.assetPath).readAsStringSync(),
  );
}

/// Every kana of the real seed as items, in teaching order, with ids from
/// 1. Those for which [introduced] returns true are marked as introduced
/// at [introducedAt].
List<Item> seedKanaItems({
  bool Function(KanaPayload kana)? introduced,
  DateTime? introducedAt,
}) {
  final seeds = realSeed()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  final at = introducedAt ?? DateTime(2026);
  return [
    for (var i = 0; i < seeds.length; i++)
      Item(
        id: i + 1,
        kind: seeds[i].kind,
        key: seeds[i].key,
        sortOrder: seeds[i].sortOrder,
        payload: seeds[i].payload,
        introducedAt:
            introduced != null && introduced(seeds[i].payload as KanaPayload)
            ? at
            : null,
      ),
  ];
}

/// The item for [character] in [items].
Item kanaOf(List<Item> items, String character) =>
    items.firstWhere((item) => item.kana.character == character);

/// The characters of [items], in order.
List<String> charactersOf(Iterable<Item> items) => [
  for (final item in items) item.kana.character,
];
