import 'package:ippo/domain/models/rating.dart';
import 'package:ippo/domain/models/scheduling_state.dart';

/// Decides when a card is next due.
///
/// Implementations depend only on the card's scheduling state, the rating
/// and the time passed in. They never read the clock and know nothing
/// about what the card is about.
abstract interface class Scheduler {
  /// The state of a brand-new card: due immediately, no history.
  SchedulingState initialState(DateTime now);

  /// The state after reviewing a card in state [current] at [now].
  SchedulingState next(SchedulingState current, Rating rating, DateTime now);
}
