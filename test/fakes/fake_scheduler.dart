import 'package:ippo/domain/models/rating.dart';
import 'package:ippo/domain/models/scheduling_state.dart';
import 'package:ippo/domain/scheduling/scheduler.dart';

/// Predictable [Scheduler] for tests: a correct answer is due again after
/// [correctInterval], a wrong one after [wrongInterval].
class FakeScheduler implements Scheduler {
  FakeScheduler({
    this.correctInterval = const Duration(days: 1),
    this.wrongInterval = const Duration(minutes: 10),
  });

  final Duration correctInterval;
  final Duration wrongInterval;

  /// Every rating passed to [next], in order.
  final List<Rating> ratings = [];

  @override
  SchedulingState initialState(DateTime now) {
    return SchedulingState(phase: CardPhase.learning, step: 0, due: now);
  }

  @override
  SchedulingState next(SchedulingState current, Rating rating, DateTime now) {
    ratings.add(rating);
    final wrong = rating == Rating.again;
    return SchedulingState(
      phase: wrong ? CardPhase.relearning : CardPhase.review,
      due: now.add(wrong ? wrongInterval : correctInterval),
      stability: wrong ? 0.5 : correctInterval.inMinutes / (24 * 60),
      difficulty: 5,
      lastReview: now,
    );
  }
}
