import 'dart:convert';

import 'kana_splitter.dart';
import 'word_builder.dart';

/// The word list failed one of its own checks.
class WordListCheckException implements Exception {
  const WordListCheckException(this.message);

  final String message;

  @override
  String toString() => 'Word list check failed: $message';
}

/// Checks a word list and writes it as text.
class WordFile {
  const WordFile();

  static const String formatName = 'ippo-words';
  static const int formatVersion = 1;

  /// A list far outside this range means the inputs are wrong.
  static const int minWords = 300;
  static const int maxWords = 3000;

  /// Throws [WordListCheckException] unless [words] is a valid list.
  void check(List<Word> words, {required KanaSplitter splitter}) {
    void require(bool ok, String message) {
      if (!ok) throw WordListCheckException(message);
    }

    require(
      words.length >= minWords && words.length <= maxWords,
      '${words.length} words is outside $minWords to $maxWords',
    );
    final taught = {for (final k in splitter.all) k.key};
    final ids = <String>{};
    final forms = <String>{};
    for (var i = 0; i < words.length; i++) {
      final word = words[i];
      final name = '${word.id} (${word.reading})';
      require(ids.add(word.id), 'id ${word.id} appears twice');
      require(
        forms.add(word.form),
        '${word.reading} (${word.written ?? 'kana'}) appears twice',
      );
      require(word.order == i + 1, '$name has order ${word.order}');
      require(word.level == 5 || word.level == 4, '$name has a bad level');
      require(
        word.meanings.isNotEmpty &&
            word.meanings.length <= WordBuilder.maxMeanings,
        '$name has ${word.meanings.length} meanings',
      );
      for (final meaning in word.meanings) {
        require(
          meaning.trim().isNotEmpty &&
              !meaning.contains('(') &&
              !meaning.contains(')'),
          '$name has the meaning "$meaning"',
        );
      }
      require(word.kana.isNotEmpty, '$name needs no kana');
      for (final kana in word.kana) {
        require(taught.contains(kana.key), '$name needs ${kana.key}');
      }
      final fresh = splitter.split(word.reading);
      require(
        fresh != null &&
            {for (final k in fresh) k.key}.length == word.kana.length &&
            fresh.every((k) => word.kana.any((w) => w.key == k.key)),
        '$name: its kana do not match its reading',
      );
    }
  }

  /// The file's text: a small header, then one word per line.
  String encode(
    List<Word> words, {
    required String dictionaryDate,
    required String dictionaryVersion,
  }) {
    const encoder = JsonEncoder.withIndent('  ');
    final header = encoder.convert({
      'format': formatName,
      'formatVersion': formatVersion,
      'dictionaryDate': dictionaryDate,
      'dictionaryFileVersion': dictionaryVersion,
      'licence': 'CC BY-SA 4.0',
      'sources': sources,
    });
    final lines = [
      for (final word in words) '    ${jsonEncode(word.toJson())}',
    ].join(',\n');
    // Splice the words in before the header's closing brace.
    final open = header.substring(0, header.lastIndexOf('}')).trimRight();
    return '$open,\n  "words": [\n$lines\n  ]\n}\n';
  }

  /// Who made the data this list is built from.
  static const List<Map<String, String>> sources = [
    {
      'name': 'JMdict',
      'by': 'Electronic Dictionary Research and Development Group (EDRDG)',
      'licence': 'CC BY-SA 4.0',
      'url': 'https://www.edrdg.org/wiki/index.php/JMdict-EDICT_Dictionary_Project',
      'via': 'https://github.com/scriptin/jmdict-simplified',
    },
    {
      'name': 'JLPT vocabulary lists, levels N5 and N4',
      'by': 'Jonathan Waller; matched to JMdict entries by Stephen Kraus',
      'licence': 'CC BY (lists), CC BY-SA 4.0 (matched copy)',
      'url': 'https://github.com/stephenmk/yomitan-jlpt-vocab',
    },
  ];
}
