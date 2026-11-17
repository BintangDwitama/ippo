import 'package:ippo/domain/models/scheduling_state.dart';
import 'package:meta/meta.dart';

/// How a card asks its question.
enum PromptType {
  /// Show the character, choose the romaji from four options.
  charToSoundChoice,

  /// Play the sound, choose the character from four options.
  soundToCharChoice,

  /// Show the character, type the romaji.
  charToSoundTyped;

  bool get needsAudio => this == PromptType.soundToCharChoice;
  bool get isTyped => this == PromptType.charToSoundTyped;
}

/// One reviewable question about an item: an item plus a prompt type,
/// with its own schedule.
@immutable
class ReviewCard {
  const ReviewCard({
    required this.id,
    required this.itemId,
    required this.promptType,
    required this.scheduling,
    required this.createdAt,
    this.reps = 0,
    this.lapses = 0,
    this.consecutiveCorrect = 0,
  });

  final int id;
  final int itemId;
  final PromptType promptType;
  final SchedulingState scheduling;
  final DateTime createdAt;

  /// Total number of reviews.
  final int reps;

  /// Number of reviews answered wrongly.
  final int lapses;

  /// Correct reviews in a row; drives graduation to typed answers.
  final int consecutiveCorrect;

  DateTime get due => scheduling.due;

  bool isDueAt(DateTime now) => scheduling.isDueAt(now);

  ReviewCard copyWith({
    SchedulingState? scheduling,
    int? reps,
    int? lapses,
    int? consecutiveCorrect,
  }) {
    return ReviewCard(
      id: id,
      itemId: itemId,
      promptType: promptType,
      scheduling: scheduling ?? this.scheduling,
      createdAt: createdAt,
      reps: reps ?? this.reps,
      lapses: lapses ?? this.lapses,
      consecutiveCorrect: consecutiveCorrect ?? this.consecutiveCorrect,
    );
  }
}
