import 'kana_splitter.dart';
import 'word_builder.dart';

/// Writes the word list as a document a person can read through: the
/// words that become readable after each row of kana.
String buildPreview(
  BuildResult result, {
  required KanaSplitter splitter,
  required String dictionaryDate,
}) {
  final out = StringBuffer()
    ..writeln('# Word list preview')
    ..writeln()
    ..writeln(
      'Generated from JMdict dated $dictionaryDate. Do not edit: fix words '
      'through `overrides.json` and rebuild.',
    )
    ..writeln()
    ..writeln(
      '${result.words.length} words. Each section lists the words that '
      'become readable once that row of kana has been learned.',
    )
    ..writeln()
    ..writeln(
      'A `?` after the meanings marks a word whose meanings were taken '
      'from the first sense in the dictionary because nothing in the '
      'definition given by the beginner list matched. Those are the ones '
      'most worth checking.',
    )
    ..writeln();

  // Rows of kana in teaching order.
  final rows = <String, List<TaughtKana>>{};
  final sorted = splitter.all.toList()
    ..sort((a, b) => a.order.compareTo(b.order));
  for (final kana in sorted) {
    rows.putIfAbsent(_rowId(kana), () => []).add(kana);
  }
  final byRow = <String, List<Word>>{};
  for (final word in result.words) {
    byRow.putIfAbsent(_rowId(word.unlockKana), () => []).add(word);
  }

  var total = 0;
  for (final MapEntry(key: id, value: kana) in rows.entries) {
    final words = byRow[id] ?? const <Word>[];
    total += words.length;
    out
      ..writeln(
        '## ${kana.first.script}, ${kana.first.group}: '
        '${kana.map((k) => k.character).join(' ')}',
      )
      ..writeln()
      ..writeln('${words.length} new, $total in total.')
      ..writeln();
    if (words.isEmpty) continue;
    out
      ..writeln('| # | Reading | Written | Meanings | Type | Level |')
      ..writeln('|---|---|---|---|---|---|');
    for (final word in words) {
      out.writeln(
        '| ${word.order} | ${word.reading} | ${word.written ?? ''} | '
        '${word.meanings.join('; ')}${_flag(word)} | ${word.partOfSpeech} | '
        'N${word.level} |',
      );
    }
    out.writeln();
  }

  for (final reason in LeftOutReason.values) {
    final entries =
        result.leftOut.where((l) => l.reason == reason).toList();
    if (entries.isEmpty) continue;
    out
      ..writeln('## Left out: ${reason.description}')
      ..writeln()
      ..writeln('${entries.length} entries.')
      ..writeln()
      ..writeln('| Reading | Written | List definition | Level | Note |')
      ..writeln('|---|---|---|---|---|');
    for (final left in entries) {
      final e = left.entry;
      out.writeln(
        '| ${e.kana} | ${e.kanji} | ${e.definition.replaceAll('|', '/')} | '
        'N${e.level} | ${left.detail ?? ''} |',
      );
    }
    out.writeln();
  }
  return out.toString();
}

String _flag(Word word) => switch (word.meaningSource) {
      MeaningSource.firstSense => ' ?',
      MeaningSource.listDefinition => ' (from the list)',
      MeaningSource.endorsed || MeaningSource.corrected => '',
    };

String _rowId(TaughtKana kana) => '${kana.script}/${kana.group}/${kana.row}';
