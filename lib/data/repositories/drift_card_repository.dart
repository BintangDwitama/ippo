import 'package:drift/drift.dart';
import 'package:ippo/data/repositories/card_repository.dart';
import 'package:ippo/data/services/app_database.dart';
import 'package:ippo/domain/models/review_card.dart';
import 'package:ippo/domain/models/scheduling_state.dart';

class DriftCardRepository implements CardRepository {
  DriftCardRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<ReviewCard>> getCardsStream() {
    return _db
        .select(_db.cards)
        .watch()
        .map((rows) => rows.map(_toCard).toList());
  }

  @override
  Future<List<ReviewCard>> getCards() async {
    final rows = await _db.select(_db.cards).get();
    return rows.map(_toCard).toList();
  }

  @override
  Future<ReviewCard> createCard({
    required int itemId,
    required PromptType promptType,
    required SchedulingState scheduling,
    required DateTime createdAt,
  }) async {
    await _db.into(_db.cards).insert(
          CardsCompanion.insert(
            itemId: itemId,
            promptType: promptType,
            phase: scheduling.phase,
            step: Value(scheduling.step),
            due: scheduling.due,
            stability: Value(scheduling.stability),
            difficulty: Value(scheduling.difficulty),
            lastReview: Value(scheduling.lastReview),
            createdAt: createdAt,
          ),
          mode: InsertMode.insertOrIgnore,
        );
    final row = await (_db.select(_db.cards)
          ..where(
            (t) =>
                t.itemId.equals(itemId) &
                t.promptType.equalsValue(promptType),
          ))
        .getSingle();
    return _toCard(row);
  }

  @override
  Future<void> updateCard(ReviewCard card) {
    final scheduling = card.scheduling;
    return (_db.update(_db.cards)..where((t) => t.id.equals(card.id))).write(
      CardsCompanion(
        phase: Value(scheduling.phase),
        step: Value(scheduling.step),
        due: Value(scheduling.due),
        stability: Value(scheduling.stability),
        difficulty: Value(scheduling.difficulty),
        lastReview: Value(scheduling.lastReview),
        reps: Value(card.reps),
        lapses: Value(card.lapses),
        consecutiveCorrect: Value(card.consecutiveCorrect),
      ),
    );
  }

  ReviewCard _toCard(CardRow row) {
    return ReviewCard(
      id: row.id,
      itemId: row.itemId,
      promptType: row.promptType,
      scheduling: SchedulingState(
        phase: row.phase,
        step: row.step,
        due: row.due.toUtc(),
        stability: row.stability,
        difficulty: row.difficulty,
        lastReview: row.lastReview?.toUtc(),
      ),
      createdAt: row.createdAt,
      reps: row.reps,
      lapses: row.lapses,
      consecutiveCorrect: row.consecutiveCorrect,
    );
  }
}
