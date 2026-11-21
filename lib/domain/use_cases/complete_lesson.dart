import 'package:ippo/data/repositories/card_repository.dart';
import 'package:ippo/data/repositories/item_repository.dart';
import 'package:ippo/data/repositories/unit_of_work.dart';
import 'package:ippo/domain/models/item.dart';
import 'package:ippo/domain/models/review_card.dart';
import 'package:ippo/domain/scheduling/scheduler.dart';

/// Records a finished lesson: marks its kana as introduced and creates
/// their first review cards, all or nothing. Marks are introduced but get
/// no cards, because there is nothing to ask about them.
class CompleteLesson {
  CompleteLesson({
    required this._itemRepository,
    required this._cardRepository,
    required this._unitOfWork,
    required this._scheduler,
  });

  /// The cards every newly introduced kana starts with.
  static const List<PromptType> initialPromptTypes = [
    PromptType.charToSoundChoice,
    PromptType.soundToCharChoice,
  ];

  final ItemRepository _itemRepository;
  final CardRepository _cardRepository;
  final UnitOfWork _unitOfWork;
  final Scheduler _scheduler;

  Future<void> call({required List<Item> items, required DateTime now}) {
    return _unitOfWork.run(() async {
      await _itemRepository.markIntroduced(
        items.map((item) => item.id).toList(),
        now,
      );
      for (final item in items) {
        if (item.kana.isMark) continue;
        for (final promptType in initialPromptTypes) {
          await _cardRepository.createCard(
            itemId: item.id,
            promptType: promptType,
            scheduling: _scheduler.initialState(now),
            createdAt: now,
          );
        }
      }
    });
  }
}
