import 'dart:convert';

import 'package:ippo/data/repositories/item_repository.dart';
import 'package:ippo/domain/models/item.dart';
import 'package:ippo/domain/models/seed_item.dart';

/// Loads the bundled kana into the database on first launch.
class KanaSeedLoader {
  KanaSeedLoader({
    required this._itemRepository,
    required this._loadSeedJson,
  });

  static const String assetPath = 'assets/seed/kana.json';

  final ItemRepository _itemRepository;
  final Future<String> Function() _loadSeedJson;

  /// Inserts any kana not yet in the database. Safe to call on every launch.
  Future<void> seed() async {
    final seedItems = parse(await _loadSeedJson());
    await _itemRepository.insertSeedItems(seedItems);
  }

  /// Throws [FormatException] if [json] is not a valid kana seed file.
  static List<SeedItem> parse(String json) {
    final Object? decoded = jsonDecode(json);
    if (decoded is! List<Object?>) {
      throw const FormatException('Kana seed must be a JSON array');
    }
    return decoded.map(_parseEntry).toList(growable: false);
  }

  static SeedItem _parseEntry(Object? entry) {
    if (entry is! Map<String, Object?>) {
      throw const FormatException('Kana seed entry must be a JSON object');
    }
    final script = entry['script'];
    final character = entry['character'];
    final romaji = entry['romaji'];
    final alt = entry['alt'];
    final order = entry['order'];
    final mnemonic = entry['mnemonic'];
    if (script is! String ||
        character is! String ||
        romaji is! String ||
        alt is! List<Object?> ||
        order is! int ||
        mnemonic is! String) {
      throw FormatException('Invalid kana seed entry: $entry');
    }
    return SeedItem(
      kind: ItemKind.kana,
      key: '$script:$romaji',
      sortOrder: order,
      payload: KanaPayload(
        character: character,
        script: KanaScript.values.byName(script),
        romaji: romaji,
        alternativeRomaji: alt.cast<String>().toList(growable: false),
      ),
      defaultMnemonic: mnemonic,
    );
  }
}
