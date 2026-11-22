import 'package:ippo/domain/models/item.dart';
import 'package:ippo/domain/study_calendar.dart';

/// Chooses the words for the next word lesson.
class GetNextWordLesson {
  const GetNextWordLesson();

  /// New words a day. Separate from the quota of new kana.
  static const int dailyQuota = 5;

  /// The most words one lesson introduces.
  static const int maxBatchSize = 5;

  /// The words the learner could start today: not yet introduced, and
  /// readable with the kana introduced so far, in learning order.
  ///
  /// With [currentKeys], words outside it are never offered: they were
  /// dropped from the word list by a later version of the app.
  List<Item> available({
    required List<Item> items,
    Set<String>? currentKeys,
  }) {
    final knownKana = {
      for (final item in items)
        if (item.isKana && item.isIntroduced) item.key,
    };
    return [
      for (final item in items)
        if (item.isWord &&
            !item.isIntroduced &&
            (currentKeys == null || currentKeys.contains(item.key)) &&
            item.word.kanaKeys.every(knownKana.contains))
          item,
    ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  /// The next lesson: up to [maxBatchSize] available words, never more
  /// than today's quota leaves. Empty when the quota is used up or no
  /// unlearned word is readable yet.
  List<Item> call({
    required List<Item> items,
    required DateTime now,
    Set<String>? currentKeys,
  }) {
    final introducedToday = items
        .where(
          (item) =>
              item.isWord &&
              item.introducedAt != null &&
              StudyCalendar.isSameDay(item.introducedAt!, now),
        )
        .length;
    final left = dailyQuota - introducedToday;
    if (left <= 0) return const [];
    final size = left < maxBatchSize ? left : maxBatchSize;
    return available(items: items, currentKeys: currentKeys)
        .take(size)
        .toList();
  }
}
