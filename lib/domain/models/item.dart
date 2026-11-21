import 'package:meta/meta.dart';

/// The kinds of thing that can be learned. Later stages add vocabulary
/// and kanji here; cards and scheduling do not change.
enum ItemKind { kana }

enum KanaScript { hiragana, katakana }

/// The part of a script a kana belongs to.
enum KanaGroup {
  /// The 46 kana of the basic table.
  basic,

  /// Basic kana with voicing marks, including the half-voiced p row.
  voiced,

  /// A kana followed by a small ya, yu or yo, read as one beat.
  combination,
}

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
    this.group = KanaGroup.basic,
    this.row = '',
    this._family,
    this.lookalikes = const [],
  });

  final String character;
  final KanaScript script;

  /// The reading taught to the learner, e.g. "shi".
  final String romaji;

  /// Other romanisations accepted in typed answers, e.g. "si".
  final List<String> alternativeRomaji;

  final KanaGroup group;

  /// The consonant line the kana belongs to, for example "k" or "ky".
  /// Empty when unknown.
  final String row;

  final String? _family;

  /// The reading of the unvoiced basic form. Kana that share a family
  /// are partners: か and が, or は, ば and ぱ.
  String get family => _family ?? romaji;

  /// Characters of the same script that are easily mistaken for this one.
  final List<String> lookalikes;

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
