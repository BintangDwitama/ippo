import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:ippo/domain/models/rating.dart';
import 'package:ippo/domain/models/scheduling_state.dart';
import 'package:ippo/domain/scheduling/scheduler.dart';

/// [Scheduler] backed by the FSRS algorithm.
///
/// This is the only file that knows about the `fsrs` package.
class FsrsScheduler implements Scheduler {
  FsrsScheduler({
    double desiredRetention = 0.9,
    bool enableFuzzing = true,
  }) : _fsrs = fsrs.Scheduler(
          desiredRetention: desiredRetention,
          enableFuzzing: enableFuzzing,
        );

  final fsrs.Scheduler _fsrs;

  @override
  SchedulingState initialState(DateTime now) {
    return SchedulingState(
      phase: CardPhase.learning,
      step: 0,
      due: now.toUtc(),
    );
  }

  @override
  SchedulingState next(SchedulingState current, Rating rating, DateTime now) {
    final result = _fsrs.reviewCard(
      _toFsrsCard(current),
      _toFsrsRating(rating),
      reviewDateTime: now.toUtc(),
    );
    return _fromFsrsCard(result.card);
  }

  fsrs.Card _toFsrsCard(SchedulingState state) {
    return fsrs.Card(
      cardId: 0,
      state: switch (state.phase) {
        CardPhase.learning => fsrs.State.learning,
        CardPhase.review => fsrs.State.review,
        CardPhase.relearning => fsrs.State.relearning,
      },
      step: state.step,
      stability: state.stability,
      difficulty: state.difficulty,
      due: state.due.toUtc(),
      lastReview: state.lastReview?.toUtc(),
    );
  }

  SchedulingState _fromFsrsCard(fsrs.Card card) {
    return SchedulingState(
      phase: switch (card.state) {
        fsrs.State.learning => CardPhase.learning,
        fsrs.State.review => CardPhase.review,
        fsrs.State.relearning => CardPhase.relearning,
      },
      step: card.step,
      stability: card.stability,
      difficulty: card.difficulty,
      due: card.due,
      lastReview: card.lastReview,
    );
  }

  fsrs.Rating _toFsrsRating(Rating rating) => switch (rating) {
        Rating.again => fsrs.Rating.again,
        Rating.hard => fsrs.Rating.hard,
        Rating.good => fsrs.Rating.good,
        Rating.easy => fsrs.Rating.easy,
      };
}
