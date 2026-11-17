/// Turns a goal into a number of new kana per day.
class CalculateDailyQuota {
  const CalculateDailyQuota();

  /// New kana per day when no goal is active.
  static const int defaultQuota = 5;

  /// The quota for a day that starts with [notIntroduced] kana still to
  /// introduce and [daysRemaining] days until the deadline.
  int call({required int notIntroduced, required int daysRemaining}) {
    if (notIntroduced <= 0) return 0;
    final days = daysRemaining < 1 ? 1 : daysRemaining;
    return (notIntroduced / days).ceil();
  }

  /// How many more kana may be introduced today, given that
  /// [introducedToday] already have been.
  int remainingToday({
    required int notIntroduced,
    required int introducedToday,
    required int daysRemaining,
  }) {
    final quotaAtStartOfDay = call(
      notIntroduced: notIntroduced + introducedToday,
      daysRemaining: daysRemaining,
    );
    final left = quotaAtStartOfDay - introducedToday;
    if (left <= 0) return 0;
    return left < notIntroduced ? left : notIntroduced;
  }
}
