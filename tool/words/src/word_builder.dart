import 'beginner_list.dart';
import 'dictionary.dart';
import 'kana_splitter.dart';

/// Where a word's meanings came from.
enum MeaningSource {
  /// Dictionary glosses that the beginner list's own definition names.
  endorsed,

  /// The first glosses of the dictionary's first sense; nothing in the
  /// beginner list's definition matched. Worth a second look.
  firstSense,

  /// The beginner list's definition, because the dictionary gave nothing
  /// usable.
  listDefinition,

  /// Written by hand in the corrections file.
  corrected,
}

/// One word of the list.
class Word {
  const Word({
    required this.id,
    required this.reading,
    required this.written,
    required this.meanings,
    required this.partOfSpeech,
    required this.level,
    required this.kana,
    required this.isCommon,
    this.meaningSource = MeaningSource.endorsed,
    this.order = 0,
  });

  final String id;
  final String reading;

  /// Null for a word written in kana.
  final String? written;
  final List<String> meanings;
  final String partOfSpeech;
  final int level;

  /// The app's kana needed to read the word, in order of first use.
  final List<TaughtKana> kana;

  /// Whether the dictionary marks this reading as common.
  final bool isCommon;

  /// Not written to the word file; shown in the preview for review.
  final MeaningSource meaningSource;

  /// Position in the learning order, from 1; 0 until the list is ordered.
  final int order;

  /// The teaching position of the last kana the learner needs.
  int get unlockOrder => unlockKana.order;

  /// The kana whose row unlocks this word.
  TaughtKana get unlockKana =>
      kana.reduce((a, b) => a.order >= b.order ? a : b);

  Word copyWith({
    List<String>? meanings,
    String? Function()? written,
    MeaningSource? meaningSource,
    int? order,
  }) {
    return Word(
      id: id,
      reading: reading,
      written: written == null ? this.written : written(),
      meanings: meanings ?? this.meanings,
      partOfSpeech: partOfSpeech,
      level: level,
      kana: kana,
      isCommon: isCommon,
      meaningSource: meaningSource ?? this.meaningSource,
      order: order ?? this.order,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'reading': reading,
        'written': written,
        'meanings': meanings,
        'partOfSpeech': partOfSpeech,
        'level': level,
        'order': order,
        'kana': [for (final k in kana) k.key],
      };
}

/// A correction made by hand to one entry of the beginner list, keyed in
/// the corrections file by the entry's id in that list.
class WordOverride {
  const WordOverride({
    this.exclude = false,
    this.useEntry,
    this.meanings,
    this.written,
    this.hasWritten = false,
  });

  factory WordOverride.fromJson(Map<String, Object?> json) {
    final unknown = json.keys.toSet().difference(_fields);
    if (unknown.isNotEmpty) {
      throw FormatException('Unknown correction field: ${unknown.first}');
    }
    return WordOverride(
      exclude: json['exclude'] == true,
      useEntry: json['useEntry'] as String?,
      meanings: (json['meanings'] as List<Object?>?)?.cast<String>(),
      written: json['written'] as String?,
      hasWritten: json.containsKey('written'),
    );
  }

  /// `note` is free text for whoever reads the file; it changes nothing.
  static const Set<String> _fields = {
    'exclude',
    'useEntry',
    'meanings',
    'written',
    'note',
  };

  /// Leave the word out.
  final bool exclude;

  /// Build the word from this dictionary entry instead of the one the
  /// beginner list names, for a row matched to the wrong entry.
  final String? useEntry;
  final List<String>? meanings;

  /// The written form to use; null with [hasWritten] means "none".
  final String? written;
  final bool hasWritten;
}

/// Why a beginner list entry is not in the word list.
enum LeftOutReason {
  notInDictionary('not found in the dictionary'),
  unreadable('needs a kana the app does not teach'),
  restrictedSense(
    'the dictionary marks it archaic, obsolete, rare, vulgar or derogatory',
  ),
  noMeaning('no usable meaning'),
  excludedByOverride('excluded by a correction'),
  sameReading('set aside: another word has the same reading');

  const LeftOutReason(this.description);

  final String description;
}

class LeftOut {
  const LeftOut(this.entry, this.reason, [this.detail]);

  final BeginnerEntry entry;
  final LeftOutReason reason;

  /// For example the untaught character, or the word that was kept.
  final String? detail;
}

class BuildResult {
  const BuildResult({required this.words, required this.leftOut});

  /// The list, in learning order.
  final List<Word> words;
  final List<LeftOut> leftOut;
}

/// A correction names an entry that is not a candidate word.
class StaleOverrideException implements Exception {
  const StaleOverrideException(this.id);

  final String id;

  @override
  String toString() =>
      'The correction for "$id" does not match any candidate word. '
      'Remove it from overrides.json or fix its id.';
}

/// Builds the word list from the beginner list and the dictionary.
class WordBuilder {
  const WordBuilder({required this.splitter});

  final KanaSplitter splitter;

  /// Dictionary tags on a sense that keep a word out of the list.
  static const Set<String> restrictedTags = {
    'arch',
    'obs',
    'rare',
    'vulg',
    'derog',
    'X',
  };

  /// Tags on a kanji form that make it unsuitable to show a beginner.
  static const Set<String> unusualKanjiTags = {'rK', 'sK', 'oK', 'iK', 'ateji'};

  /// The most meanings a word may have, corrections included.
  static const int maxMeanings = 3;

  /// The most meanings taken from the dictionary automatically.
  static const int dictionaryMeanings = 2;

  /// The dictionary entries a build will look up: those the beginner list
  /// names, and those corrections redirect to.
  static Set<String> wantedIds(
    List<BeginnerEntry> beginnerList,
    Map<String, WordOverride> overrides,
  ) {
    return {
      for (final entry in beginnerList) entry.id,
      for (final override in overrides.values)
        if (override.useEntry != null) override.useEntry!,
    };
  }

  BuildResult build({
    required List<BeginnerEntry> beginnerList,
    required Dictionary dictionary,
    Map<String, WordOverride> overrides = const {},
  }) {
    final leftOut = <LeftOut>[];
    final candidates = <Word>[];
    final entryOf = <String, BeginnerEntry>{};
    final corrected = <String>{};
    final seenIds = <String>{};

    for (final entry in beginnerList) {
      // The same dictionary entry can appear at both levels or under two
      // spellings; the first, lower-level mention wins.
      if (!seenIds.add(entry.id)) continue;
      final override = overrides[entry.id];
      final dictEntry = dictionary.entries[override?.useEntry ?? entry.id];
      if (dictEntry == null) {
        leftOut.add(LeftOut(entry, LeftOutReason.notInDictionary));
        continue;
      }
      var word = _wordFor(entry, dictEntry, leftOut);
      if (word == null) continue;
      if (override != null) {
        corrected.add(entry.id);
        if (override.exclude) {
          leftOut.add(LeftOut(entry, LeftOutReason.excludedByOverride));
          continue;
        }
        word = word.copyWith(
          meanings: override.meanings?.take(maxMeanings).toList(),
          meaningSource:
              override.meanings == null ? null : MeaningSource.corrected,
          written: override.hasWritten ? () => override.written : null,
        );
      }
      if (entryOf.containsKey(word.id)) continue;
      candidates.add(word);
      entryOf[word.id] = entry;
    }

    for (final id in overrides.keys) {
      if (!corrected.contains(id)) throw StaleOverrideException(id);
    }

    // One word per reading: the lower level, then the common one, then
    // the smaller id.
    candidates.sort(_preference);
    final byReading = <String, Word>{};
    for (final word in candidates) {
      final kept = byReading[word.reading];
      if (kept == null) {
        byReading[word.reading] = word;
      } else {
        leftOut.add(
          LeftOut(
            entryOf[word.id]!,
            LeftOutReason.sameReading,
            'kept ${kept.written ?? kept.reading} (${kept.meanings.first})',
          ),
        );
      }
    }

    final ordered = byReading.values.toList()..sort(_learningOrder);
    return BuildResult(
      words: [
        for (var i = 0; i < ordered.length; i++)
          ordered[i].copyWith(order: i + 1),
      ],
      leftOut: leftOut,
    );
  }

  Word? _wordFor(BeginnerEntry entry, DictEntry dict, List<LeftOut> leftOut) {
    // The list's maintainer chose the reading and spelling a beginner
    // meets; use them when the dictionary entry really has them.
    final kanaForm = dict.kana.where((k) => k.text == entry.kana).firstOrNull ??
        dict.kana.where((k) => k.common).firstOrNull ??
        dict.kana.first;
    final reading = kanaForm.text;

    String? unknown;
    final kana = splitter.split(reading, onUnknown: (c) => unknown = c);
    if (kana == null) {
      leftOut.add(LeftOut(entry, LeftOutReason.unreadable, unknown));
      return null;
    }

    final written = _writtenFor(entry, dict, kanaForm);
    final senses = [
      for (final sense in dict.senses)
        if (sense.appliesTo(reading: reading, written: written) &&
            !sense.misc.any(restrictedTags.contains))
          sense,
    ];
    if (senses.isEmpty) {
      leftOut.add(LeftOut(entry, LeftOutReason.restrictedSense));
      return null;
    }

    var source = MeaningSource.endorsed;
    var meanings = _endorsedMeanings(entry.definition, senses);
    if (meanings.isEmpty) {
      source = MeaningSource.firstSense;
      meanings = _firstMeanings(senses.first.glosses);
    }
    if (meanings.isEmpty) {
      source = MeaningSource.listDefinition;
      meanings = _firstMeanings(entry.definition.split(','));
    }
    if (meanings.isEmpty) {
      leftOut.add(LeftOut(entry, LeftOutReason.noMeaning));
      return null;
    }

    final seen = <String>{};
    return Word(
      id: dict.id,
      reading: reading,
      written: written,
      meanings: meanings,
      // The sense the first meaning came from decides the type.
      partOfSpeech: partOfSpeechOf(
        senses
            .firstWhere(
              (s) => s.glosses.any((g) => cleanMeaning(g) == meanings.first),
              orElse: () => senses.first,
            )
            .partOfSpeech,
      ),
      level: entry.level,
      kana: [
        for (final k in kana)
          if (seen.add(k.key)) k,
      ],
      isCommon: kanaForm.common,
      meaningSource: source,
    );
  }

  /// The spelling to show: the list's, when the dictionary has it as an
  /// ordinary form; none when the list gives the word in kana.
  String? _writtenFor(BeginnerEntry entry, DictEntry dict, DictForm kanaForm) {
    if (entry.kanji.isEmpty) return null;
    bool usable(DictForm form) =>
        !form.tags.any(unusualKanjiTags.contains) &&
        (kanaForm.appliesToKanji.contains('*') ||
            kanaForm.appliesToKanji.contains(form.text));
    final listed = dict.kanji.where((k) => k.text == entry.kanji).firstOrNull;
    if (listed != null && usable(listed)) return listed.text;
    final ordinary = dict.kanji.where(usable).toList();
    if (ordinary.isEmpty) return null;
    return (ordinary.where((k) => k.common).firstOrNull ?? ordinary.first).text;
  }

  /// Dictionary glosses that say what the beginner list's definition
  /// says, in the list's order.
  ///
  /// The dictionary's first sense is often not the one a beginner needs
  /// (its first gloss for 足 is "foot; paw", the list says "foot, leg").
  /// The list knows which meanings matter; the dictionary has the careful
  /// wording. This takes the dictionary's wording for the list's choices.
  List<String> _endorsedMeanings(String definition, List<DictSense> senses) {
    final glosses = <String, String>{};
    for (final sense in senses) {
      for (final gloss in sense.glosses) {
        if (gloss.contains('(')) continue;
        glosses.putIfAbsent(_comparable(gloss), () => gloss.trim());
      }
    }
    final result = <String>[];
    for (final term in definition.split(RegExp('[,;]'))) {
      final match = glosses[_comparable(term)];
      if (match == null || result.contains(match)) continue;
      result.add(match);
      if (result.length == dictionaryMeanings) break;
    }
    return result;
  }

  /// The first few glosses, preferring ones without a parenthesised
  /// explanation: cutting the parentheses out of "good (tasting)" leaves
  /// "good", which is not what the word means.
  List<String> _firstMeanings(List<String> glosses) {
    List<String> take(Iterable<String> from) {
      final result = <String>[];
      for (final gloss in from) {
        final cleaned = cleanMeaning(gloss);
        if (cleaned.isEmpty || result.contains(cleaned)) continue;
        result.add(cleaned);
        if (result.length == dictionaryMeanings) break;
      }
      return result;
    }

    final plain = take(glosses.where((g) => !g.contains('(')));
    return plain.isNotEmpty ? plain : take(glosses);
  }

  static int _preference(Word a, Word b) {
    final byLevel = b.level.compareTo(a.level);
    if (byLevel != 0) return byLevel;
    if (a.isCommon != b.isCommon) return a.isCommon ? -1 : 1;
    return int.parse(a.id).compareTo(int.parse(b.id));
  }

  static int _learningOrder(Word a, Word b) {
    final byLevel = b.level.compareTo(a.level);
    if (byLevel != 0) return byLevel;
    final byUnlock = a.unlockOrder.compareTo(b.unlockOrder);
    if (byUnlock != 0) return byUnlock;
    final byLength = a.reading.runes.length.compareTo(b.reading.runes.length);
    if (byLength != 0) return byLength;
    return a.reading.compareTo(b.reading);
  }
}

final RegExp _parenthesised = RegExp(r'\s*\([^()]*\)');
final RegExp _spaces = RegExp(r'\s+');
final RegExp _article = RegExp('^(a|an|the) ');

/// A gloss as shown to a learner: parenthesised explanations removed.
String cleanMeaning(String gloss) {
  var text = gloss;
  // Twice, for one level of nesting.
  text = text.replaceAll(_parenthesised, '');
  text = text.replaceAll(_parenthesised, '');
  if (text.contains('(') || text.contains(')')) return '';
  return text.replaceAll(_spaces, ' ').trim();
}

/// A meaning reduced to what matters when comparing two sources: case,
/// spacing and a leading article ignored.
String _comparable(String text) => text
    .toLowerCase()
    .replaceAll(_spaces, ' ')
    .trim()
    .replaceFirst(_article, '');

/// A plain part of speech from the dictionary's tags, decided by the
/// first tag that says something.
String partOfSpeechOf(List<String> tags) {
  for (final tag in tags) {
    if (tag == 'adj-i' || tag == 'adj-ix') return 'i-adjective';
    if (tag == 'adj-na') return 'na-adjective';
    if (tag == 'adv' || tag == 'adv-to') return 'adverb';
    if (tag == 'pn') return 'pronoun';
    if (tag == 'exp') return 'expression';
    if (tag == 'n' || tag.startsWith('n-') || tag == 'adj-no') return 'noun';
    // "vs" alone marks a noun that takes suru; real verbs are v1, v5k...
    if (tag.startsWith('v') && tag != 'vs') return 'verb';
  }
  return 'other';
}
