/// The parts of a JMdict entry the word list uses, read from the JSON
/// published by jmdict-simplified.
class DictEntry {
  const DictEntry({
    required this.id,
    required this.kanji,
    required this.kana,
    required this.senses,
  });

  factory DictEntry.fromJson(Map<String, Object?> json) {
    List<Map<String, Object?>> maps(String name) =>
        (json[name]! as List<Object?>).cast<Map<String, Object?>>();
    List<String> strings(Object? value) =>
        (value as List<Object?>? ?? const []).cast<String>();
    return DictEntry(
      id: json['id']! as String,
      kanji: [
        for (final k in maps('kanji'))
          DictForm(
            text: k['text']! as String,
            common: k['common'] == true,
            tags: strings(k['tags']),
          ),
      ],
      kana: [
        for (final k in maps('kana'))
          DictForm(
            text: k['text']! as String,
            common: k['common'] == true,
            tags: strings(k['tags']),
            appliesToKanji: strings(k['appliesToKanji']),
          ),
      ],
      senses: [
        for (final s in maps('sense'))
          DictSense(
            partOfSpeech: strings(s['partOfSpeech']),
            misc: strings(s['misc']),
            appliesToKanji: strings(s['appliesToKanji']),
            appliesToKana: strings(s['appliesToKana']),
            glosses: [
              for (final g
                  in (s['gloss']! as List<Object?>).cast<Map<String, Object?>>())
                if (g['lang'] == 'eng') g['text']! as String,
            ],
          ),
      ],
    );
  }

  /// JMdict's own entry number, stable across releases.
  final String id;
  final List<DictForm> kanji;
  final List<DictForm> kana;
  final List<DictSense> senses;
}

/// One spelling of an entry: a kanji form or a kana form.
class DictForm {
  const DictForm({
    required this.text,
    required this.common,
    this.tags = const [],
    this.appliesToKanji = const ['*'],
  });

  final String text;
  final bool common;
  final List<String> tags;

  /// For a kana form: the kanji forms it reads. `*` means all.
  final List<String> appliesToKanji;
}

class DictSense {
  const DictSense({
    required this.partOfSpeech,
    required this.glosses,
    this.misc = const [],
    this.appliesToKanji = const ['*'],
    this.appliesToKana = const ['*'],
  });

  final List<String> partOfSpeech;
  final List<String> misc;
  final List<String> appliesToKanji;
  final List<String> appliesToKana;

  /// English glosses, in dictionary order.
  final List<String> glosses;

  /// Whether this sense is given for a word read [reading] and written
  /// [written] (null for a word written in kana).
  bool appliesTo({required String reading, required String? written}) {
    final kanaOk =
        appliesToKana.contains('*') || appliesToKana.contains(reading);
    final kanjiOk = written == null ||
        appliesToKanji.contains('*') ||
        appliesToKanji.contains(written);
    return kanaOk && kanjiOk;
  }
}

/// The dictionary file: its date and its entries by id.
class Dictionary {
  const Dictionary({
    required this.version,
    required this.date,
    required this.entries,
  });

  /// Reads the decoded JSON of a jmdict-simplified file, keeping only the
  /// entries in [wantedIds]. Throws [FormatException] for a file whose
  /// major version this script does not know.
  factory Dictionary.fromJson(
    Map<String, Object?> json, {
    required Set<String> wantedIds,
  }) {
    final version = json['version'];
    if (version is! String || !version.startsWith('$supportedMajor.')) {
      throw FormatException(
        'Unsupported dictionary file version "$version"; this script reads '
        'version $supportedMajor.x of the jmdict-simplified format.',
      );
    }
    final words = (json['words']! as List<Object?>).cast<Map<String, Object?>>();
    return Dictionary(
      version: version,
      date: json['dictDate']! as String,
      entries: {
        for (final word in words)
          if (wantedIds.contains(word['id']))
            word['id']! as String: DictEntry.fromJson(word),
      },
    );
  }

  /// The major version of the jmdict-simplified format this script reads.
  static const int supportedMajor = 3;

  final String version;

  /// The date of the JMdict data, as `YYYY-MM-DD`.
  final String date;
  final Map<String, DictEntry> entries;
}
