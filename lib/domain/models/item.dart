import 'package:meta/meta.dart';

/// The kinds of thing that can be learned. Later stages add vocabulary
/// and kanji here; cards and scheduling do not change.
enum ItemKind { kana }

enum KanaScript { hiragana, katakana }

/// Kind-specific content of an [Item].
@immutable
sealed class ItemPayload {
  const ItemPayload();
}

@immutable
class KanaPayload extends ItemPayload {
  const KanaPayload({
    required this.character,
    required this.script,
    required this.romaji,
    this.alternativeRomaji = const [],
  });

  final String character;
  final KanaScript script;

  /// The reading taught to the learner, e.g. "shi".
  final String romaji;

  /// Other romanisations accepted in typed answers, e.g. "si".
  final List<String> alternativeRomaji;

  List<String> get acceptedRomaji => [romaji, ...alternativeRomaji];
}

/// One thing to learn, such as a single kana.
@immutable
class Item {
  const Item({
    required this.id,
    required this.kind,
    required this.key,
    required this.sortOrder,
    required this.payload,
    this.introducedAt,
  });

  final int id;
  final ItemKind kind;

  /// Stable identifier from the seed data, e.g. "hiragana:ka".
  final String key;

  /// Teaching order within the kind (gojūon order for kana).
  final int sortOrder;

  final ItemPayload payload;

  /// When a lesson introduced the item; null if not yet introduced.
  final DateTime? introducedAt;

  bool get isIntroduced => introducedAt != null;

  /// The kana content. Only valid for items of kind [ItemKind.kana].
  KanaPayload get kana => payload as KanaPayload;
}
