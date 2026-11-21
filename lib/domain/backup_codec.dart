import 'dart:convert';

import 'package:ippo/domain/models/appearance_mode.dart';
import 'package:ippo/domain/models/backup_snapshot.dart';
import 'package:ippo/domain/models/goal.dart';
import 'package:ippo/domain/models/rating.dart';
import 'package:ippo/domain/models/reminder_time.dart';
import 'package:ippo/domain/models/review_card.dart';
import 'package:ippo/domain/models/scheduling_state.dart';

/// Why a file could not be used as a backup.
enum BackupFormatProblem {
  /// Not JSON, or not marked as an Ippo backup.
  notABackup,

  /// Written by a newer version of the app than this one.
  newerVersion,

  /// An Ippo backup, but a part of it is missing or damaged.
  corrupt,

  /// Names items this version of the app does not have.
  unknownItems,
}

class BackupFormatException implements Exception {
  const BackupFormatException(this.problem, [this.detail]);

  final BackupFormatProblem problem;

  /// What exactly was wrong, for logs and tests.
  final String? detail;

  @override
  String toString() =>
      'BackupFormatException(${problem.name}${detail == null ? '' : ': $detail'})';
}

/// Turns a [BackupSnapshot] into the text of a backup file and back.
///
/// Times are written in UTC as ISO 8601 and enums by name.
class BackupCodec {
  const BackupCodec();

  static const String formatName = 'ippo-backup';

  /// The version this app writes, and the newest it can read.
  static const int formatVersion = 1;

  String encode(BackupSnapshot snapshot) {
    return jsonEncode({
      'format': formatName,
      'formatVersion': formatVersion,
      'exportedAt': _time(snapshot.exportedAt),
      'items': [
        for (final item in snapshot.introducedItems)
          {'key': item.key, 'introducedAt': _time(item.introducedAt)},
      ],
      'mnemonics': [
        for (final mnemonic in snapshot.learnerMnemonics)
          {'key': mnemonic.key, 'learnerText': mnemonic.learnerText},
      ],
      'cards': [for (final card in snapshot.cards) _encodeCard(card)],
      'goals': [
        for (final goal in snapshot.goals)
          {
            'targetSet': goal.targetSet.name,
            'targetAccuracy': goal.targetAccuracy,
            'createdAt': _time(goal.createdAt),
            'deadline': _time(goal.deadline),
            'status': goal.status.name,
          },
      ],
      'settings': {
        'dailyReviewCap': snapshot.settings.dailyReviewCap,
        'reminderTime': snapshot.settings.reminderTime?.toString(),
        'appearanceMode': snapshot.settings.appearanceMode.name,
      },
    });
  }

  Map<String, Object?> _encodeCard(BackupCard card) {
    final scheduling = card.scheduling;
    return {
      'key': card.itemKey,
      'promptType': card.promptType.name,
      'phase': scheduling.phase.name,
      'step': scheduling.step,
      'due': _time(scheduling.due),
      'stability': scheduling.stability,
      'difficulty': scheduling.difficulty,
      'lastReview': scheduling.lastReview == null
          ? null
          : _time(scheduling.lastReview!),
      'reps': card.reps,
      'lapses': card.lapses,
      'consecutiveCorrect': card.consecutiveCorrect,
      'createdAt': _time(card.createdAt),
      'reviews': [
        for (final review in card.reviews)
          {
            'reviewedAt': _time(review.reviewedAt),
            'rating': review.rating.name,
            'wasCorrect': review.wasCorrect,
            'phaseBefore': review.phaseBefore.name,
            'elapsedDays': review.elapsedDays,
          },
      ],
    };
  }

  /// Throws [BackupFormatException] if [text] is not a backup this app
  /// can read.
  BackupSnapshot decode(String text) {
    final Object? root;
    try {
      root = jsonDecode(text);
    } on FormatException {
      throw const BackupFormatException(
        BackupFormatProblem.notABackup,
        'not JSON',
      );
    }
    if (root is! Map<String, Object?> || root['format'] != formatName) {
      throw const BackupFormatException(
        BackupFormatProblem.notABackup,
        'format marker missing',
      );
    }
    final version = root['formatVersion'];
    if (version is! int || version < 1) {
      throw const BackupFormatException(
        BackupFormatProblem.corrupt,
        'formatVersion',
      );
    }
    if (version > formatVersion) {
      throw BackupFormatException(
        BackupFormatProblem.newerVersion,
        'version $version',
      );
    }

    try {
      return _decodeVersion1(root);
    } on BackupFormatException {
      rethrow;
    } on Object catch (error) {
      // A wrong type or a bad date anywhere means the file is damaged.
      throw BackupFormatException(BackupFormatProblem.corrupt, '$error');
    }
  }

  BackupSnapshot _decodeVersion1(Map<String, Object?> root) {
    final cards = [
      for (final entry in _list(root, 'cards')) _decodeCard(_map(entry)),
    ];
    final seen = <(String, PromptType)>{};
    for (final card in cards) {
      if (!seen.add((card.itemKey, card.promptType))) {
        throw BackupFormatException(
          BackupFormatProblem.corrupt,
          'duplicate card ${card.itemKey} ${card.promptType.name}',
        );
      }
    }

    final settings = _map(root['settings']);
    final cap = settings['dailyReviewCap'] as int;
    if (cap < 1) {
      throw const BackupFormatException(
        BackupFormatProblem.corrupt,
        'dailyReviewCap',
      );
    }

    return BackupSnapshot(
      exportedAt: _parseTime(root['exportedAt']),
      introducedItems: [
        for (final entry in _list(root, 'items').map(_map))
          BackupItem(
            key: entry['key'] as String,
            introducedAt: _parseTime(entry['introducedAt']),
          ),
      ],
      learnerMnemonics: [
        for (final entry in _list(root, 'mnemonics').map(_map))
          BackupMnemonic(
            key: entry['key'] as String,
            learnerText: entry['learnerText'] as String,
          ),
      ],
      cards: cards,
      goals: [
        for (final entry in _list(root, 'goals').map(_map))
          BackupGoal(
            targetSet: _enum(GoalTargetSet.values, entry['targetSet']),
            targetAccuracy: (entry['targetAccuracy'] as num).toDouble(),
            createdAt: _parseTime(entry['createdAt']),
            deadline: _parseTime(entry['deadline']),
            status: _enum(GoalStatus.values, entry['status']),
          ),
      ],
      settings: BackupSettings(
        dailyReviewCap: cap,
        reminderTime: _parseReminderTime(settings['reminderTime']),
        appearanceMode: _enum(
          AppearanceMode.values,
          settings['appearanceMode'],
        ),
      ),
    );
  }

  BackupCard _decodeCard(Map<String, Object?> entry) {
    final lastReview = entry['lastReview'];
    return BackupCard(
      itemKey: entry['key'] as String,
      promptType: _enum(PromptType.values, entry['promptType']),
      scheduling: SchedulingState(
        phase: _enum(CardPhase.values, entry['phase']),
        step: entry['step'] as int?,
        due: _parseTime(entry['due']),
        stability: (entry['stability'] as num?)?.toDouble(),
        difficulty: (entry['difficulty'] as num?)?.toDouble(),
        lastReview: lastReview == null ? null : _parseTime(lastReview),
      ),
      createdAt: _parseTime(entry['createdAt']),
      reps: entry['reps'] as int,
      lapses: entry['lapses'] as int,
      consecutiveCorrect: entry['consecutiveCorrect'] as int,
      reviews: [
        for (final review in _list(entry, 'reviews').map(_map))
          BackupReview(
            reviewedAt: _parseTime(review['reviewedAt']),
            rating: _enum(Rating.values, review['rating']),
            wasCorrect: review['wasCorrect'] as bool,
            phaseBefore: _enum(CardPhase.values, review['phaseBefore']),
            elapsedDays: review['elapsedDays'] as int,
          ),
      ],
    );
  }

  static String _time(DateTime time) => time.toUtc().toIso8601String();

  static DateTime _parseTime(Object? value) =>
      DateTime.parse(value as String).toUtc();

  static ReminderTime? _parseReminderTime(Object? value) {
    if (value == null) return null;
    final parts = (value as String).split(':');
    if (parts.length != 2) throw FormatException('reminderTime $value');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      throw FormatException('reminderTime $value');
    }
    return ReminderTime(hour: hour, minute: minute);
  }

  static List<Object?> _list(Map<String, Object?> map, String name) =>
      map[name] as List<Object?>;

  static Map<String, Object?> _map(Object? value) =>
      value as Map<String, Object?>;

  static T _enum<T extends Enum>(List<T> values, Object? name) =>
      values.firstWhere(
        (value) => value.name == name,
        orElse: () => throw FormatException('unknown value $name'),
      );
}
