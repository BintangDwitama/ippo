import 'package:meta/meta.dart';

/// Where a card is in its learning life cycle.
enum CardPhase { learning, review, relearning }

/// The scheduler's memory of one card. Independent of what the card is about.
@immutable
class SchedulingState {
  const SchedulingState({
    required this.phase,
    required this.due,
    this.step,
    this.stability,
    this.difficulty,
    this.lastReview,
  });

  final CardPhase phase;

  /// When the card should next be shown. Always UTC.
  final DateTime due;

  /// Position in the learning or relearning steps; null in the review phase.
  final int? step;

  /// Days until recall probability falls to the target retention.
  final double? stability;

  final double? difficulty;

  /// Always UTC. Null until the first review.
  final DateTime? lastReview;

  bool isDueAt(DateTime now) => !due.isAfter(now);

  @override
  bool operator ==(Object other) =>
      other is SchedulingState &&
      other.phase == phase &&
      other.due == due &&
      other.step == step &&
      other.stability == stability &&
      other.difficulty == difficulty &&
      other.lastReview == lastReview;

  @override
  int get hashCode =>
      Object.hash(phase, due, step, stability, difficulty, lastReview);
}
