/// One row of the beginner vocabulary list.
class BeginnerEntry {
  const BeginnerEntry({
    required this.id,
    required this.kana,
    required this.kanji,
    required this.definition,
    required this.level,
  });

  /// The JMdict entry this row was matched to by the list's maintainer.
  final String id;

  /// The reading the list gives.
  final String kana;

  /// The spelling the list gives; empty when it gives the word in kana.
  final String kanji;

  /// The list's own short definition.
  final String definition;

  /// 5 for the first exam level, 4 for the second.
  final int level;
}

/// Parses one level file of the beginner list: a CSV with the header
/// `jmdict_seq,kana,kanji,waller_definition`.
List<BeginnerEntry> parseBeginnerList(String csv, {required int level}) {
  final rows = parseCsv(csv);
  if (rows.isEmpty ||
      rows.first.join(',') != 'jmdict_seq,kana,kanji,waller_definition') {
    throw const FormatException('Unexpected beginner list header');
  }
  return [
    for (final row in rows.skip(1))
      if (row.length == 4)
        BeginnerEntry(
          id: row[0].trim(),
          kana: row[1].trim(),
          kanji: row[2].trim(),
          definition: row[3].trim(),
          level: level,
        )
      else
        throw FormatException('Beginner list row has ${row.length} fields'),
  ];
}

/// A small CSV reader: comma-separated, fields optionally in double
/// quotes, a doubled quote inside a quoted field standing for one quote.
List<List<String>> parseCsv(String text) {
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var inQuotes = false;
  var fieldStarted = false;

  void endField() {
    row.add(field.toString());
    field.clear();
    fieldStarted = false;
  }

  void endRow() {
    endField();
    rows.add(row);
    row = <String>[];
  }

  for (var i = 0; i < text.length; i++) {
    final c = text[i];
    if (inQuotes) {
      if (c == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        field.write(c);
      }
    } else if (c == '"' && !fieldStarted) {
      inQuotes = true;
      fieldStarted = true;
    } else if (c == ',') {
      endField();
    } else if (c == '\n') {
      endRow();
    } else if (c != '\r') {
      field.write(c);
      fieldStarted = true;
    }
  }
  if (fieldStarted || field.isNotEmpty || row.isNotEmpty) endRow();
  return rows;
}
