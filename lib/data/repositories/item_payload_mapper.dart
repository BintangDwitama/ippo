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
          'group': payload.group.name,
          'row': payload.row,
          'family': payload.family,
          'lookalikes': payload.lookalikes,
          if (payload.sample != null) 'sample': payload.sample,
        }),
      WordPayload() => jsonEncode({
          'reading': payload.reading,
          if (payload.written != null) 'written': payload.written,
          'meanings': payload.meanings,
          'partOfSpeech': payload.partOfSpeech,
          'level': payload.level,
          'kana': payload.kanaKeys,
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
      ItemKind.word => _decodeWord(decoded),
    };
  }

  WordPayload _decodeWord(Map<String, Object?> map) {
    final reading = map['reading'];
    final written = map['written'];
    final meanings = map['meanings'];
    final partOfSpeech = map['partOfSpeech'];
    final level = map['level'];
    final kana = map['kana'];
    if (reading is! String ||
        written is! String? ||
        meanings is! List<Object?> ||
        partOfSpeech is! String ||
        level is! int ||
        kana is! List<Object?>) {
      throw const FormatException('Invalid word payload');
    }
    return WordPayload(
      reading: reading,
      written: written,
      meanings: meanings.cast<String>().toList(growable: false),
      partOfSpeech: partOfSpeech,
      level: level,
      kanaKeys: kana.cast<String>().toList(growable: false),
    );
  }

  KanaPayload _decodeKana(Map<String, Object?> map) {
    final character = map['character'];
    final script = map['script'];
    final romaji = map['romaji'];
    final alt = map['alt'] ?? const <Object?>[];
    // Payloads stored before groups existed lack the next four fields;
    // they describe basic kana.
    final group = map['group'] ?? KanaGroup.basic.name;
    final row = map['row'] ?? '';
    final family = map['family'];
    final lookalikes = map['lookalikes'] ?? const <Object?>[];
    final sample = map['sample'];
    if (character is! String ||
        script is! String ||
        romaji is! String ||
        alt is! List<Object?> ||
        group is! String ||
        row is! String ||
        family is! String? ||
        lookalikes is! List<Object?> ||
        sample is! String?) {
      throw const FormatException('Invalid kana payload');
    }
    return KanaPayload(
      character: character,
      script: KanaScript.values.byName(script),
      romaji: romaji,
      alternativeRomaji: alt.cast<String>().toList(growable: false),
      group: KanaGroup.values.byName(group),
      row: row,
      family: family,
      lookalikes: lookalikes.cast<String>().toList(growable: false),
      sample: sample,
    );
  }
}
