import 'package:flutter_test/flutter_test.dart';
import 'package:ippo/domain/models/rating.dart';
import 'package:ippo/domain/models/scheduling_state.dart';
import 'package:ippo/domain/scheduling/fsrs_scheduler.dart';

void main() {
  final scheduler = FsrsScheduler(enableFuzzing: false);
  final start = DateTime.utc(2026, 1, 1, 9);

  /// Reviews with "good" at each due time until the card reaches review.
  SchedulingState graduate() {
    var state = scheduler.initialState(start);
    while (state.phase != CardPhase.review) {
      state = scheduler.next(state, Rating.good, state.due);
    }
    return state;
  }

  test('a new card is due immediately and has no history', () {
    final state = scheduler.initialState(start);

    expect(state.isDueAt(start), isTrue);
    expect(state.phase, CardPhase.learning);
    expect(state.lastReview, isNull);
    expect(state.stability, isNull);
  });

  test('good answers move a new card into review within a few steps', () {
    final state = graduate();

    expect(state.phase, CardPhase.review);
    expect(state.due.difference(state.lastReview!).inDays,
        greaterThanOrEqualTo(1));
  });

  test('a good answer in review lengthens the interval', () {
    final first = graduate();
    final firstInterval = first.due.difference(first.lastReview!);

    final second = scheduler.next(first, Rating.good, first.due);
    final secondInterval = second.due.difference(second.lastReview!);

    expect(secondInterval, greaterThan(firstInterval));
  });

  test('a wrong answer brings the card back within the same day', () {
    final reviewed = graduate();

    final lapsed = scheduler.next(reviewed, Rating.again, reviewed.due);

    expect(lapsed.phase, CardPhase.relearning);
    expect(lapsed.due.difference(reviewed.due), lessThan(const Duration(days: 1)));
  });

  test('a wrong answer on a new card keeps it in learning, due soon', () {
    final state =
        scheduler.next(scheduler.initialState(start), Rating.again, start);

    expect(state.phase, CardPhase.learning);
    expect(state.due.difference(start), lessThan(const Duration(hours: 1)));
  });

  test('local times are accepted and results are UTC', () {
    final local = DateTime(2026, 1, 1, 9);

    final state = scheduler.next(
      scheduler.initialState(local),
      Rating.good,
      local,
    );

    expect(state.due.isUtc, isTrue);
    expect(state.lastReview!.isUtc, isTrue);
  });
}
