import 'package:drift/drift.dart';
import 'package:ippo/data/repositories/review_repository.dart';
import 'package:ippo/data/services/app_database.dart';
import 'package:ippo/domain/models/rating.dart';
import 'package:ippo/domain/models/review_record.dart';
import 'package:ippo/domain/models/scheduling_state.dart';

class DriftReviewRepository implements ReviewRepository {
  DriftReviewRepository(this._db);

  final AppDatabase _db;

  SimpleSelectStatement<$ReviewRecordsTable, ReviewRecordRow> get _ordered =>
      _db.select(_db.reviewRecords)
        ..orderBy([(t) => OrderingTerm(expression: t.id)]);

  @override
  Stream<List<ReviewRecord>> getReviewsStream() {
    return _ordered.watch().map((rows) => rows.map(_toRecord).toList());
  }

  @override
  Future<List<ReviewRecord>> getReviews() async {
    final rows = await _ordered.get();
    return rows.map(_toRecord).toList();
  }

  @override
  Future<void> addReview({
    required int cardId,
    required DateTime reviewedAt,
    required Rating rating,
    required bool wasCorrect,
    required CardPhase phaseBefore,
    required int elapsedDays,
  }) {
    return _db.into(_db.reviewRecords).insert(
          ReviewRecordsCompanion.insert(
            cardId: cardId,
            reviewedAt: reviewedAt,
            rating: rating,
            wasCorrect: wasCorrect,
            phaseBefore: phaseBefore,
            elapsedDays: elapsedDays,
          ),
        );
  }

  ReviewRecord _toRecord(ReviewRecordRow row) {
    return ReviewRecord(
      id: row.id,
      cardId: row.cardId,
      reviewedAt: row.reviewedAt.toUtc(),
      rating: row.rating,
      wasCorrect: row.wasCorrect,
      phaseBefore: row.phaseBefore,
      elapsedDays: row.elapsedDays,
    );
  }
}
