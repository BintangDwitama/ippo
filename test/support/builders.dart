import 'package:ippo/domain/models/item.dart';
import 'package:ippo/domain/models/review_card.dart';
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
    ),
    introducedAt: introducedAt,
  );
}

/// [hiraganaCount] hiragana (ids from 1) followed by [katakanaCount]
/// katakana (ids from 101). The first [introduced] of the whole list are
/// marked as introduced at [introducedAt].
List<Item> kanaItems({
  int hiraganaCount = 12,
  int katakanaCount = 0,
  int introduced = 0,
  DateTime? introducedAt,
}) {
  final at = introducedAt ?? DateTime(2026);
  final items = <Item>[
    for (var i = 0; i < hiraganaCount; i++)
      kanaItem(
        id: i + 1,
        character: _hiragana[i].$1,
        romaji: _hiragana[i].$2,
        sortOrder: i,
      ),
    for (var i = 0; i < katakanaCount; i++)
      kanaItem(
        id: i + 101,
        character: _katakana[i].$1,
        romaji: _katakana[i].$2,
        script: KanaScript.katakana,
        sortOrder: i + 100,
      ),
  ];
  return [
    for (var i = 0; i < items.length; i++)
      i < introduced
          ? kanaItem(
              id: items[i].id,
              character: items[i].kana.character,
              romaji: items[i].kana.romaji,
              script: items[i].kana.script,
              sortOrder: items[i].sortOrder,
              introducedAt: at,
            )
          : items[i],
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
