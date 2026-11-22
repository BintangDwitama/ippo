// Builds the app's word list from the JMdict dictionary and the beginner
// vocabulary list. Run from the repository root:
//
//   dart run tool/words/build_words.dart --dictionary path/to/jmdict-eng.json
//
// See data/words/README.md for where the dictionary file comes from.
import 'dart:convert';
import 'dart:io';

import 'src/beginner_list.dart';
import 'src/dictionary.dart';
import 'src/kana_splitter.dart';
import 'src/preview.dart';
import 'src/word_builder.dart';
import 'src/word_file.dart';

const _usage = '''
Usage: dart run tool/words/build_words.dart --dictionary <file> [--out <dir>]

  --dictionary  The English JMdict JSON file from a jmdict-simplified
                release (jmdict-eng-<version>.json, unpacked).
  --out         Folder to write into. Default: data/words
''';

Future<void> main(List<String> args) async {
  String? option(String name) {
    final index = args.indexOf(name);
    return index >= 0 && index + 1 < args.length ? args[index + 1] : null;
  }

  final dictionaryPath = option('--dictionary');
  final outDir = option('--out') ?? 'data/words';
  if (dictionaryPath == null) {
    stderr.write(_usage);
    exitCode = 64;
    return;
  }

  try {
    final splitter = KanaSplitter.fromSeedJson(
      File('assets/seed/kana.json').readAsStringSync(),
    );
    final beginnerList = [
      ...parseBeginnerList(
        File('data/words/sources/jlpt_n5.csv').readAsStringSync(),
        level: 5,
      ),
      ...parseBeginnerList(
        File('data/words/sources/jlpt_n4.csv').readAsStringSync(),
        level: 4,
      ),
    ];
    final overridesFile = File('data/words/overrides.json');
    final overrides = overridesFile.existsSync()
        ? {
            for (final entry in (jsonDecode(overridesFile.readAsStringSync())
                    as Map<String, Object?>)
                .entries)
              entry.key: WordOverride.fromJson(
                entry.value! as Map<String, Object?>,
              ),
          }
        : const <String, WordOverride>{};

    stdout.writeln('Reading $dictionaryPath ...');
    final dictionary = Dictionary.fromJson(
      await _decodeFile(dictionaryPath),
      wantedIds: WordBuilder.wantedIds(beginnerList, overrides),
    );

    final result = WordBuilder(splitter: splitter).build(
      beginnerList: beginnerList,
      dictionary: dictionary,
      overrides: overrides,
    );

    // Checked before anything is written, so a bad build leaves the
    // existing files as they are.
    const wordFile = WordFile();
    wordFile.check(result.words, splitter: splitter);
    final text = wordFile.encode(
      result.words,
      dictionaryDate: dictionary.date,
      dictionaryVersion: dictionary.version,
    );
    final preview = buildPreview(
      result,
      splitter: splitter,
      dictionaryDate: dictionary.date,
    );

    Directory(outDir).createSync(recursive: true);
    File('$outDir/words.json').writeAsStringSync(text);
    File('$outDir/preview.md').writeAsStringSync(preview);

    stdout
      ..writeln('Dictionary dated ${dictionary.date}.')
      ..writeln('${result.words.length} words written to $outDir/words.json');
    for (final reason in LeftOutReason.values) {
      final count = result.leftOut.where((l) => l.reason == reason).length;
      if (count > 0) stdout.writeln('  $count left out: ${reason.description}');
    }
    for (final source in MeaningSource.values) {
      final count =
          result.words.where((w) => w.meaningSource == source).length;
      stdout.writeln('  $count meanings: ${source.name}');
    }
  } on Object catch (error) {
    stderr.writeln('Build failed, nothing written: $error');
    exitCode = 1;
  }
}

/// Decodes a large JSON file without first holding it as one string.
Future<Map<String, Object?>> _decodeFile(String path) async {
  final decoded = await File(path)
      .openRead()
      .transform(utf8.decoder)
      .transform(json.decoder)
      .first;
  return decoded! as Map<String, Object?>;
}
