import 'dart:convert';

/// One kana the app teaches, as far as building the word list cares.
class TaughtKana {
  const TaughtKana({
    required this.key,
    required this.character,
    required this.script,
    required this.group,
    required this.row,
    required this.order,
  });

  /// The kana's stable key, for example "hiragana:ka".
  final String key;
  final String character;
  final String script;
  final String group;
  final String row;

  /// Its position in the teaching order.
  final int order;
}

/// Splits a reading into the kana the app teaches.
class KanaSplitter {
  KanaSplitter(Iterable<TaughtKana> kana)
      : _byCharacter = {for (final k in kana) k.character: k};

  /// Reads the app's kana seed file (`assets/seed/kana.json`).
  factory KanaSplitter.fromSeedJson(String json) {
    final entries = (jsonDecode(json) as List<Object?>)
        .cast<Map<String, Object?>>();
    return KanaSplitter([
      for (final entry in entries)
        TaughtKana(
          key: entry['key'] as String? ??
              '${entry['script']}:${entry['romaji']}',
          character: entry['character']! as String,
          script: entry['script']! as String,
          group: entry['group']! as String,
          row: entry['row']! as String,
          order: entry['order']! as int,
        ),
    ]);
  }

  final Map<String, TaughtKana> _byCharacter;

  Iterable<TaughtKana> get all => _byCharacter.values;

  /// The kana that spell [reading], left to right, taking two characters
  /// where they form one combination kana (きゃ). Returns null if any part
  /// is not a kana the app teaches; [onUnknown] is then told which.
  List<TaughtKana>? split(String reading, {void Function(String)? onUnknown}) {
    final characters = reading.runes.map(String.fromCharCode).toList();
    final result = <TaughtKana>[];
    var i = 0;
    while (i < characters.length) {
      final pair = i + 1 < characters.length
          ? _byCharacter[characters[i] + characters[i + 1]]
          : null;
      if (pair != null) {
        result.add(pair);
        i += 2;
        continue;
      }
      final single = _byCharacter[characters[i]];
      if (single == null) {
        onUnknown?.call(characters[i]);
        return null;
      }
      result.add(single);
      i += 1;
    }
    return result.isEmpty ? null : result;
  }
}
