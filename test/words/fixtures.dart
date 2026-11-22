import 'dart:io';

import '../../tool/words/src/beginner_list.dart';
import '../../tool/words/src/dictionary.dart';
import '../../tool/words/src/kana_splitter.dart';

/// The app's real kana, so the tests split readings as a build does.
KanaSplitter realSplitter() =>
    KanaSplitter.fromSeedJson(File('assets/seed/kana.json').readAsStringSync());

/// One dictionary entry in the shape jmdict-simplified publishes.
Map<String, Object?> entry(
  String id, {
  required List<Object> kana,
  List<Object> kanji = const [],
  required List<Map<String, Object?>> senses,
}) {
  Map<String, Object?> form(Object value) => value is String
      ? {'text': value, 'common': true, 'tags': <String>[]}
      : value as Map<String, Object?>;
  return {
    'id': id,
    'kanji': [for (final k in kanji) form(k)],
    'kana': [
      for (final k in kana) {'appliesToKanji': ['*'], ...form(k)},
    ],
    'sense': senses,
  };
}

/// One sense of an entry.
Map<String, Object?> sense(
  List<String> glosses, {
  List<String> partOfSpeech = const ['n'],
  List<String> misc = const [],
  List<String> appliesToKanji = const ['*'],
  List<String> appliesToKana = const ['*'],
}) {
  return {
    'partOfSpeech': partOfSpeech,
    'misc': misc,
    'appliesToKanji': appliesToKanji,
    'appliesToKana': appliesToKana,
    'gloss': [
      for (final g in glosses) {'lang': 'eng', 'text': g},
    ],
  };
}

/// A dictionary file holding [entries].
Map<String, Object?> dictionaryJson(
  List<Map<String, Object?>> entries, {
  String version = '3.6.2',
}) {
  return {'version': version, 'dictDate': '2026-01-01', 'words': entries};
}

Dictionary dictionaryOf(List<Map<String, Object?>> entries) {
  return Dictionary.fromJson(
    dictionaryJson(entries),
    wantedIds: {for (final e in entries) e['id']! as String},
  );
}

/// One row of the beginner list.
BeginnerEntry listed(
  String id,
  String kana, {
  String kanji = '',
  String definition = '',
  int level = 5,
}) {
  return BeginnerEntry(
    id: id,
    kana: kana,
    kanji: kanji,
    definition: definition,
    level: level,
  );
}
