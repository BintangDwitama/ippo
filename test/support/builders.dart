import 'package:ippo/domain/models/goal.dart';
import 'package:ippo/domain/models/item.dart';
import 'package:ippo/domain/models/rating.dart';
import 'package:ippo/domain/models/review_card.dart';
import 'package:ippo/domain/models/review_record.dart';
import 'package:ippo/domain/models/scheduling_state.dart';

/// Test data builders shared by unit tests.

const _hiragana = [
  ('あ', 'a'), ('い', 'i'), ('う', 'u'), ('え', 'e'), ('お', 'o'),
  ('か', 'ka'), ('き', 'ki'), ('く', 'ku'), ('け', 'ke'), ('こ', 'ko'),
  ('さ', 'sa'), ('し', 'shi'),
];

const _katakana = [
  ('ア', 'a'), ('イ', 'i'), ('ウ', 'u'), ('エ', 'e'), ('オ', 'o'),
  ('カ', 'ka'),
];

Item kanaItem({
  required int id,
  String character = 'あ',
  String romaji = 'a',
  KanaScript script = KanaScript.hiragana,
  List<String> alternatives = const [],
  int? sortOrder,
  DateTime? introducedAt,
  KanaGroup group = KanaGroup.basic,
  String row = '',
  String? family,
  List<String> lookalikes = const [],
}) {
  return Item(
    id: id,
    kind: ItemKind.kana,
    key: '${script.name}:$romaji',
    sortOrder: sortOrder ?? id,
    payload: KanaPayload(
      character: character,
      script: script,
      romaji: romaji,
      alternativeRomaji: alternatives,
      group: group,
      row: row,
      family: family,
      lookalikes: lookalikes,
    ),
    introducedAt: introducedAt,
  );
}

/// [hiraganaCount] hiragana (ids from 1) followed by [katakanaCount]
/// katakana (ids from 101), in teaching order. The first [introduced] of
/// the whole list are marked as introduced at [introducedAt].
///
/// The first few of each script are real kana; the rest are placeholders
/// with unique characters and readings.
List<Item> kanaItems({
  int hiraganaCount = 12,
  int katakanaCount = 0,
  int introduced = 0,
  DateTime? introducedAt,
}) {
  final at = introducedAt ?? DateTime(2026);
  var position = 0;
  Item build(int index, KanaScript script) {
    final real = script == KanaScript.hiragana ? _hiragana : _katakana;
    final isHiragana = script == KanaScript.hiragana;
    final item = kanaItem(
      id: index + (isHiragana ? 1 : 101),
      character: index < real.length
          ? real[index].$1
          : '${isHiragana ? 'h' : 'k'}$index',
      romaji: index < real.length ? real[index].$2 : 'r$index',
      script: script,
      sortOrder: index + (isHiragana ? 0 : 1000),
      // Rows of five, as in the basic table.
      row: 'r${index ~/ 5}',
      introducedAt: position < introduced ? at : null,
    );
    position++;
    return item;
  }

  return [
    for (var i = 0; i < hiraganaCount; i++) build(i, KanaScript.hiragana),
    for (var i = 0; i < katakanaCount; i++) build(i, KanaScript.katakana),
  ];
}

ReviewCard reviewCard({
  required int id,
  required int itemId,
  PromptType promptType = PromptType.charToSoundChoice,
  DateTime? due,
  CardPhase phase = CardPhase.learning,
  double? stability,
  DateTime? lastReview,
  int reps = 0,
  int lapses = 0,
  int consecutiveCorrect = 0,
}) {
  return ReviewCard(
    id: id,
    itemId: itemId,
    promptType: promptType,
    scheduling: SchedulingState(
      phase: phase,
      step: phase == CardPhase.review ? null : 0,
      due: due ?? DateTime.utc(2026),
      stability: stability,
      lastReview: lastReview,
    ),
    createdAt: DateTime.utc(2026),
    reps: reps,
    lapses: lapses,
    consecutiveCorrect: consecutiveCorrect,
  );
}

ReviewRecord reviewRecord({
  required int id,
  required int cardId,
  required DateTime reviewedAt,
  bool wasCorrect = true,
}) {
  return ReviewRecord(
    id: id,
    cardId: cardId,
    reviewedAt: reviewedAt,
    rating: wasCorrect ? Rating.good : Rating.again,
    wasCorrect: wasCorrect,
    phaseBefore: CardPhase.review,
    elapsedDays: 1,
  );
}

Goal goal({
  int id = 1,
  GoalTargetSet targetSet = GoalTargetSet.hiragana,
  double targetAccuracy = 0.9,
  required DateTime createdAt,
  int deadlineDays = 14,
  GoalStatus status = GoalStatus.active,
}) {
  return Goal(
    id: id,
    targetSet: targetSet,
    targetAccuracy: targetAccuracy,
    createdAt: createdAt,
    deadline: DateTime(createdAt.year, createdAt.month, createdAt.day + deadlineDays),
    status: status,
  );
}
