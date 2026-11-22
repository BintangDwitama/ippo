import 'dart:convert';

import 'package:ippo/data/repositories/item_repository.dart';
import 'package:ippo/domain/models/item.dart';
import 'package:ippo/domain/models/seed_item.dart';
import 'package:ippo/domain/models/word_list_info.dart';

/// The bundled word list, parsed.
class WordSeed {
  const WordSeed({required this.info, required this.items});

  final WordListInfo info;
  final List<SeedItem> items;
}

/// Brings the words in the database in line with the bundled word list.
class WordSeedLoader {
  WordSeedLoader({
    required this._itemRepository,
    required this._loadSeedJson,
  });

  /// The file the word build script writes; bundled as it is.
  static const String assetPath = 'data/words/words.json';

  static const String formatName = 'ippo-words';

  /// The newest version of the file format this app reads.
  static const int formatVersion = 1;

  /// Words sort after every kana, in the list's own order.
  static const int sortOrderBase = 100000;

  final ItemRepository _itemRepository;
  final Future<String> Function() _loadSeedJson;

  /// Adds words that are missing and updates the content of those already
  /// there. Never touches learner data. Safe to call on every launch.
  Future<WordListInfo> seed() async {
    final seed = parse(await _loadSeedJson());
    await _itemRepository.syncSeedItems(seed.items);
    return seed.info;
  }

  /// Throws [FormatException] if [json] is not a word list this app reads.
  static WordSeed parse(String json) {
    final Object? decoded = jsonDecode(json);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Word list must be a JSON object');
    }
    final version = decoded['formatVersion'];
    final date = decoded['dictionaryDate'];
    final words = decoded['words'];
    if (decoded['format'] != formatName ||
        version is! int ||
        date is! String ||
        words is! List<Object?>) {
      throw const FormatException('Not an Ippo word list');
    }
    if (version > formatVersion) {
      throw FormatException('Word list format $version is too new');
    }
    final items = words.map(_parseWord).toList(growable: false);
    return WordSeed(
      info: WordListInfo(
        dictionaryDate: date,
        keys: {for (final item in items) item.key},
      ),
      items: items,
    );
  }

  static SeedItem _parseWord(Object? entry) {
    if (entry is! Map<String, Object?>) {
      throw const FormatException('Word list entry must be a JSON object');
    }
    final id = entry['id'];
    final reading = entry['reading'];
    final written = entry['written'];
    final meanings = entry['meanings'];
    final partOfSpeech = entry['partOfSpeech'];
    final level = entry['level'];
    final order = entry['order'];
    final kana = entry['kana'];
    if (id is! String ||
        reading is! String ||
        written is! String? ||
        meanings is! List<Object?> ||
        meanings.isEmpty ||
        partOfSpeech is! String ||
        level is! int ||
        order is! int ||
        kana is! List<Object?> ||
        kana.isEmpty) {
      throw FormatException('Invalid word list entry: $entry');
    }
    return SeedItem(
      kind: ItemKind.word,
      key: '$wordKeyPrefix$id',
      sortOrder: sortOrderBase + order,
      payload: WordPayload(
        reading: reading,
        written: written,
        meanings: meanings.cast<String>().toList(growable: false),
        partOfSpeech: partOfSpeech,
        level: level,
        kanaKeys: kana.cast<String>().toList(growable: false),
      ),
    );
  }
}
