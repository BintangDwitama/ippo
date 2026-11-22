import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ippo/domain/backup_codec.dart';
import 'package:ippo/domain/models/appearance_mode.dart';
import 'package:ippo/domain/models/goal.dart';
import 'package:ippo/domain/models/rating.dart';
import 'package:ippo/domain/models/reminder_time.dart';
import 'package:ippo/domain/models/review_card.dart';
import 'package:ippo/domain/models/scheduling_state.dart';

import '../support/backup_builders.dart';
import '../support/seed_items.dart';

void main() {
  const codec = BackupCodec();

  Matcher throwsProblem(BackupFormatProblem problem) {
    return throwsA(
      isA<BackupFormatException>().having((e) => e.problem, 'problem', problem),
    );
  }

  /// The JSON of a full snapshot with [change] applied, as text.
  String altered(void Function(Map<String, Object?> root) change) {
    final root =
        jsonDecode(codec.encode(fullSnapshot())) as Map<String, Object?>;
    change(root);
    return jsonEncode(root);
  }

  test('a snapshot survives encoding and decoding unchanged', () {
    final original = fullSnapshot();

    final decoded = codec.decode(codec.encode(original));

    // Encoding covers every field, so equal text means equal content.
    expect(codec.encode(decoded), codec.encode(original));
    expect(decoded.exportedAt, original.exportedAt);
    expect(decoded.introducedItems, hasLength(2));
    expect(
      decoded.learnerMnemonics.single.learnerText,
      'an apple with a stalk',
    );
    expect(decoded.cards, hasLength(3));
    expect(decoded.cards.first.scheduling, original.cards.first.scheduling);
    expect(decoded.cards.first.reviews.first.rating, Rating.again);
    expect(decoded.cards[1].promptType, PromptType.charToSoundTyped);
    expect(decoded.cards[1].scheduling.phase, CardPhase.relearning);
    expect(decoded.cards.last.scheduling.stability, isNull);
    expect(decoded.cards.last.scheduling.lastReview, isNull);
    expect(decoded.goals.last.targetSet, GoalTargetSet.both);
    expect(decoded.goals.first.status, GoalStatus.missed);
    expect(decoded.settings.dailyReviewCap, 60);
    expect(
      decoded.settings.reminderTime,
      const ReminderTime(hour: 19, minute: 30),
    );
    expect(decoded.settings.appearanceMode, AppearanceMode.paper);
    expect(decoded.reviewCount, 2);
  });

  test('times are written in UTC whatever zone they were given in', () {
    final local = DateTime(2026, 11, 21, 9, 15);
    final text = codec.encode(fullSnapshot(exportedAt: local));

    final root = jsonDecode(text) as Map<String, Object?>;
    expect(root['exportedAt'], local.toUtc().toIso8601String());
    expect(root['exportedAt'] as String, endsWith('Z'));
    expect(codec.decode(text).exportedAt.isUtc, isTrue);
    expect(codec.decode(text).exportedAt, local.toUtc());
  });

  test('a reminder that is off is written as null and read back', () {
    final text = altered((root) {
      (root['settings']! as Map<String, Object?>)['reminderTime'] = null;
    });

    expect(codec.decode(text).settings.reminderTime, isNull);
  });

  test('the file carries no database ids', () {
    final text = codec.encode(fullSnapshot());

    expect(text, isNot(contains('"id"')));
    expect(text, isNot(contains('"cardId"')));
    expect(text, isNot(contains('"itemId"')));
  });

  test('reads the version 1 file kept from the first release', () {
    final text = File('test/fixtures/backup_v1.json').readAsStringSync();

    final snapshot = codec.decode(text);

    expect(snapshot.exportedAt, DateTime.utc(2026, 11, 21, 2, 15));
    expect(snapshot.introducedItems.map((i) => i.key), [
      'hiragana:a',
      'hiragana:i',
    ]);
    expect(snapshot.learnerMnemonics.single.key, 'hiragana:a');
    expect(snapshot.cards, hasLength(2));
    expect(snapshot.cards.first.reps, 3);
    expect(snapshot.cards.first.scheduling.stability, 4.25);
    expect(snapshot.cards.first.reviews, hasLength(2));
    expect(snapshot.cards.last.scheduling.step, 0);
    expect(snapshot.goals.single.targetAccuracy, 0.9);
    expect(
      snapshot.settings.reminderTime,
      const ReminderTime(hour: 19, minute: 30),
    );
    expect(snapshot.settings.appearanceMode, AppearanceMode.paper);
  });

  test('reads a version 2 file with voiced and combination kana', () {
    final text = File('test/fixtures/backup_v2.json').readAsStringSync();

    final snapshot = codec.decode(text);

    expect(
      snapshot.introducedItems.map((i) => i.key),
      containsAll(['hiragana:a', 'hiragana:di', 'hiragana:kya']),
    );
    expect(snapshot.cards.last.itemKey, 'hiragana:kya');
    expect(snapshot.goals.last.targetSet, GoalTargetSet.hiraganaExtended);
    expect(snapshot.goals.first.targetSet, GoalTargetSet.hiragana);
  });

  test('writes the current version and round-trips the new goal target sets', () {
    final original = codec.decode(
      File('test/fixtures/backup_v2.json').readAsStringSync(),
    );

    final text = codec.encode(original);

    expect(text, contains('"formatVersion":${BackupCodec.formatVersion}'));
    expect(
      codec.decode(text).goals.map((g) => g.targetSet),
      [GoalTargetSet.hiragana, GoalTargetSet.hiraganaExtended],
    );
  });

  test('a version 1 hiragana goal still means the 46 basic hiragana', () {
    final snapshot = codec.decode(
      File('test/fixtures/backup_v1.json').readAsStringSync(),
    );
    final target = snapshot.goals.single.targetSet;

    expect(target, GoalTargetSet.hiragana);
    expect(
      [for (final item in seedKanaItems()) item.kana].where(target.includes),
      hasLength(46),
    );
  });

  group('refuses', () {
    test('text that is not JSON', () {
      expect(
        () => codec.decode('holiday photo'),
        throwsProblem(BackupFormatProblem.notABackup),
      );
      expect(
        () => codec.decode(''),
        throwsProblem(BackupFormatProblem.notABackup),
      );
    });

    test('JSON that is not an Ippo backup', () {
      expect(
        () => codec.decode('{"name": "something else"}'),
        throwsProblem(BackupFormatProblem.notABackup),
      );
      expect(
        () => codec.decode('[1, 2, 3]'),
        throwsProblem(BackupFormatProblem.notABackup),
      );
    });

    test('a backup written by a newer version', () {
      final text = altered(
        (root) => root['formatVersion'] = BackupCodec.formatVersion + 1,
      );

      expect(
        () => codec.decode(text),
        throwsProblem(BackupFormatProblem.newerVersion),
      );
    });

    test('a backup with a missing part', () {
      expect(
        () => codec.decode(altered((root) => root.remove('cards'))),
        throwsProblem(BackupFormatProblem.corrupt),
      );
      expect(
        () => codec.decode(altered((root) => root.remove('settings'))),
        throwsProblem(BackupFormatProblem.corrupt),
      );
      expect(
        () => codec.decode(altered((root) => root.remove('formatVersion'))),
        throwsProblem(BackupFormatProblem.corrupt),
      );
    });

    test('a backup with a damaged value', () {
      Map<String, Object?> firstCard(Map<String, Object?> root) =>
          (root['cards']! as List<Object?>).first! as Map<String, Object?>;

      expect(
        () => codec.decode(altered((r) => firstCard(r)['due'] = 'soon')),
        throwsProblem(BackupFormatProblem.corrupt),
      );
      expect(
        () => codec.decode(altered((r) => firstCard(r)['phase'] = 'napping')),
        throwsProblem(BackupFormatProblem.corrupt),
      );
      expect(
        () => codec.decode(altered((r) => firstCard(r)['reps'] = 'three')),
        throwsProblem(BackupFormatProblem.corrupt),
      );
      expect(
        () => codec.decode(
          altered((r) {
            (r['settings']! as Map<String, Object?>)['reminderTime'] = '25:99';
          }),
        ),
        throwsProblem(BackupFormatProblem.corrupt),
      );
      expect(
        () => codec.decode(
          altered((r) {
            (r['settings']! as Map<String, Object?>)['dailyReviewCap'] = 0;
          }),
        ),
        throwsProblem(BackupFormatProblem.corrupt),
      );
    });

    test('a backup with the same card twice', () {
      final text = altered((root) {
        final cards = root['cards']! as List<Object?>;
        cards.add(cards.first);
      });

      expect(
        () => codec.decode(text),
        throwsProblem(BackupFormatProblem.corrupt),
      );
    });
  });
}
