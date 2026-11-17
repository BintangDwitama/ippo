import 'dart:convert';

import 'package:ippo/domain/models/item.dart';

/// Converts kind-specific item content to and from its stored JSON.
class ItemPayloadMapper {
  const ItemPayloadMapper();

  String encode(ItemPayload payload) {
    return switch (payload) {
      KanaPayload() => jsonEncode({
          'character': payload.character,
          'script': payload.script.name,
          'romaji': payload.romaji,
          'alt': payload.alternativeRomaji,
        }),
    };
  }

  /// Throws [FormatException] if [json] is not valid for [kind].
  ItemPayload decode(ItemKind kind, String json) {
    final Object? decoded = jsonDecode(json);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Item payload must be a JSON object');
    }
    return switch (kind) {
      ItemKind.kana => _decodeKana(decoded),
    };
  }

  KanaPayload _decodeKana(Map<String, Object?> map) {
    final character = map['character'];
    final script = map['script'];
    final romaji = map['romaji'];
    final alt = map['alt'] ?? const <Object?>[];
    if (character is! String ||
        script is! String ||
        romaji is! String ||
        alt is! List<Object?>) {
      throw const FormatException('Invalid kana payload');
    }
    return KanaPayload(
      character: character,
      script: KanaScript.values.byName(script),
      romaji: romaji,
      alternativeRomaji: alt.cast<String>().toList(growable: false),
    );
  }
}
