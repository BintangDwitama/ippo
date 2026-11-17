/// How well the learner recalled a card.
///
/// Kana cards are graded automatically and only use [again] and [good];
/// [hard] and [easy] are kept for card kinds that are self-rated later.
enum Rating { again, hard, good, easy }
