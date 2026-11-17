import 'package:ippo/domain/models/review_card.dart';

/// The running state of one review session: which card is next, which
/// cards come back after a wrong answer, and the score so far.
///
/// Only the first attempt at each card counts towards the score and is
/// graded. A card answered wrongly returns later in the session as
/// ungraded practice until it is answered correctly.
class ReviewSession {
  ReviewSession(List<ReviewCard> cards)
      : _queue = [...cards],
        total = cards.length;

  /// A wrongly answered card returns after at least this many others.
  static const int _requeueGap = 2;

  final List<ReviewCard> _queue;
  final Set<int> _attempted = {};

  /// Number of distinct cards in the session.
  final int total;

  int _firstAttempts = 0;
  int _correctFirstAttempts = 0;

  ReviewCard? get current => _queue.isEmpty ? null : _queue.first;

  bool get isFinished => _queue.isEmpty;

  /// Whether the current card was already attempted in this session.
  bool get isRepeat {
    final card = current;
    return card != null && _attempted.contains(card.id);
  }

  /// Number of cards attempted at least once.
  int get reviewedCount => _firstAttempts;

  int get correctFirstAttempts => _correctFirstAttempts;

  /// Share of cards answered correctly at the first attempt, from 0 to 1.
  double get accuracy =>
      _firstAttempts == 0 ? 0 : _correctFirstAttempts / _firstAttempts;

  /// Records the answer to [current] and moves on.
  void recordAnswer({required bool wasCorrect}) {
    final card = _queue.removeAt(0);
    if (_attempted.add(card.id)) {
      _firstAttempts++;
      if (wasCorrect) _correctFirstAttempts++;
    }
    if (!wasCorrect) {
      _queue.insert(_requeueIndex(card), card);
    }
  }

  /// The earliest position at least [_requeueGap] cards away where the
  /// card does not sit next to another card of the same item.
  int _requeueIndex(ReviewCard card) {
    final start = _requeueGap < _queue.length ? _requeueGap : _queue.length;
    for (var index = start; index <= _queue.length; index++) {
      final before = index > 0 ? _queue[index - 1] : null;
      final after = index < _queue.length ? _queue[index] : null;
      if (before?.itemId != card.itemId && after?.itemId != card.itemId) {
        return index;
      }
    }
    return _queue.length;
  }
}
