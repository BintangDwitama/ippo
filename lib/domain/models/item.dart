import 'package:meta/meta.dart';

/// The kinds of thing that can be learned. Later stages add kanji here;
/// cards and scheduling do not change.
enum ItemKind { kana, word }

enum KanaScript { hiragana, katakana }

/// The part of a script a kana belongs to.
enum KanaGroup {
  /// The 46 kana of the basic table.
  basic,

  /// Basic kana with voicing marks, including the half-voiced p row.
  voiced,

  /// A kana followed by a small ya, yu or yo, read as one beat.
  combination,

  /// A sign with no sound of its own that changes the kana next to it:
  /// the small tsu and the long mark.
  mark,
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
    this.sample,
  });

  final String character;
  final KanaScript script;

  /// The reading taught to the learner, e.g. "shi". For a mark, which
  /// has no reading, its name, e.g. "small tsu".
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

  /// What to say in place of the character, for kana that are silent on
  /// their own. A mark's sample is a pair that differs only by the mark.
  final String? sample;

  /// The text to speak for this kana.
  String get spoken => sample ?? character;

  /// Whether this kana is a mark. A mark has no reading, so it is never
  /// asked about and has no review cards.
  bool get isMark => group == KanaGroup.mark;

  /// Characters of the same script that are easily mistaken for this one.
  final List<String> lookalikes;

  List<String> get acceptedRomaji => [romaji, ...alternativeRomaji];
}

/// How the key of every word item begins; the rest is the word's
/// identifier in the word list.
const String wordKeyPrefix = 'word:';

/// A word of the beginner word list.
@immutable
class WordPayload extends ItemPayload {
  const WordPayload({
    required this.reading,
    required this.meanings,
    required this.partOfSpeech,
    required this.level,
    required this.kanaKeys,
    this.written,
  });

  /// How the word is read, in kana. This is also what is spoken: a voice
  /// can misread kanji.
  final String reading;

  /// How the word is usually written, when that is not its reading.
  /// Shown for recognition only; it tells apart words that share a
  /// reading, such as 雨 and 飴, both あめ.
  final String? written;

  /// One to three short English meanings, the most useful first.
  final List<String> meanings;

  /// For example "noun" or "verb", as the word list names it.
  final String partOfSpeech;

  /// The exam level the word is listed at: 5 is the first, 4 the second.
  final int level;

  /// Keys of the kana needed to read the word. The word can be learned
  /// once all of them have been introduced.
  final List<String> kanaKeys;

  /// All meanings as one line of text.
  String get meaningText => meanings.join('; ');
}

/// One thing to learn, such as a single kana or a word.
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

  bool get isKana => kind == ItemKind.kana;
  bool get isWord => kind == ItemKind.word;

  /// The kana content. Throws for an item of another kind.
  KanaPayload get kana => payload as KanaPayload;

  /// The word content. Throws for an item of another kind.
  WordPayload get word => payload as WordPayload;
}
