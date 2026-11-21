import 'dart:convert';

import 'package:ippo/data/repositories/item_repository.dart';
import 'package:ippo/domain/models/item.dart';
import 'package:ippo/domain/models/seed_item.dart';

/// Brings the kana in the database in line with the bundled seed file.
class KanaSeedLoader {
  KanaSeedLoader({
    required this._itemRepository,
    required this._loadSeedJson,
  });

  static const String assetPath = 'assets/seed/kana.json';

  final ItemRepository _itemRepository;
  final Future<String> Function() _loadSeedJson;

  /// Adds kana that are missing and updates the content of those already
  /// there. Never touches learner data. Safe to call on every launch.
  Future<void> seed() async {
    final seedItems = parse(await _loadSeedJson());
    await _itemRepository.syncSeedItems(seedItems);
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
    final group = entry['group'];
    final row = entry['row'];
    final family = entry['family'];
    final lookalikes = entry['lookalikes'];
    // Stated only where two kana of a script share a reading.
    final key = entry['key'];
    if (script is! String ||
        character is! String ||
        romaji is! String ||
        alt is! List<Object?> ||
        order is! int ||
        mnemonic is! String ||
        group is! String ||
        row is! String ||
        family is! String ||
        lookalikes is! List<Object?> ||
        key is! String?) {
      throw FormatException('Invalid kana seed entry: $entry');
    }
    final KanaGroup kanaGroup;
    final KanaScript kanaScript;
    try {
      kanaGroup = KanaGroup.values.byName(group);
      kanaScript = KanaScript.values.byName(script);
    } on ArgumentError {
      throw FormatException('Invalid kana seed entry: $entry');
    }
    return SeedItem(
      kind: ItemKind.kana,
      key: key ?? '$script:$romaji',
      sortOrder: order,
      payload: KanaPayload(
        character: character,
        script: kanaScript,
        romaji: romaji,
        alternativeRomaji: alt.cast<String>().toList(growable: false),
        group: kanaGroup,
        row: row,
        family: family,
        lookalikes: lookalikes.cast<String>().toList(growable: false),
      ),
      defaultMnemonic: mnemonic,
    );
  }
}
