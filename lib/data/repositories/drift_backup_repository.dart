import 'package:drift/drift.dart';
import 'package:ippo/data/repositories/backup_repository.dart';
import 'package:ippo/data/repositories/settings_repository.dart';
import 'package:ippo/data/services/app_database.dart';
import 'package:ippo/domain/models/backup_snapshot.dart';
import 'package:ippo/domain/models/scheduling_state.dart';

class DriftBackupRepository implements BackupRepository {
  DriftBackupRepository(this._db, this._settings);

  /// The tables a backup accounts for. A test fails when the database has
  /// a table that is not listed here, so a new table cannot be left out
  /// of backups by accident: add it here and to [readSnapshot] and
  /// [replaceWith].
  static const Set<String> coveredTables = {
    'items',
    'mnemonics',
    'cards',
    'review_records',
    'goals',
    'settings',
  };

  final AppDatabase _db;

  /// Settings go through their repository so the keys and their encoding
  /// stay in one place. It must use the same database.
  final SettingsRepository _settings;

  @override
  Future<BackupSnapshot> readSnapshot(DateTime now) {
    return _db.transaction(() async {
      final items = await (_db.select(
        _db.items,
      )..orderBy([(t) => OrderingTerm(expression: t.sortOrder)])).get();
      final keyById = {for (final item in items) item.id: item.itemKey};
      final orderById = {for (final item in items) item.id: item.sortOrder};

      final mnemonics = await (_db.select(
        _db.mnemonics,
      )..where((t) => t.learnerText.isNotNull())).get();
      mnemonics.sort(
        (a, b) => orderById[a.itemId]!.compareTo(orderById[b.itemId]!),
      );

      final cards = await (_db.select(
        _db.cards,
      )..orderBy([(t) => OrderingTerm(expression: t.id)])).get();
      final reviews = await (_db.select(
        _db.reviewRecords,
      )..orderBy([(t) => OrderingTerm(expression: t.id)])).get();
      final reviewsByCard = <int, List<ReviewRecordRow>>{};
      for (final review in reviews) {
        reviewsByCard.putIfAbsent(review.cardId, () => []).add(review);
      }

      final goals = await (_db.select(
        _db.goals,
      )..orderBy([(t) => OrderingTerm(expression: t.id)])).get();

      return BackupSnapshot(
        exportedAt: now.toUtc(),
        introducedItems: [
          for (final item in items)
            if (item.introducedAt != null)
              BackupItem(
                key: item.itemKey,
                introducedAt: item.introducedAt!.toUtc(),
              ),
        ],
        learnerMnemonics: [
          for (final mnemonic in mnemonics)
            BackupMnemonic(
              key: keyById[mnemonic.itemId]!,
              learnerText: mnemonic.learnerText!,
            ),
        ],
        cards: [
          for (final card in cards)
            BackupCard(
              itemKey: keyById[card.itemId]!,
              promptType: card.promptType,
              scheduling: SchedulingState(
                phase: card.phase,
                step: card.step,
                due: card.due.toUtc(),
                stability: card.stability,
                difficulty: card.difficulty,
                lastReview: card.lastReview?.toUtc(),
              ),
              createdAt: card.createdAt.toUtc(),
              reps: card.reps,
              lapses: card.lapses,
              consecutiveCorrect: card.consecutiveCorrect,
              reviews: [
                for (final review
                    in reviewsByCard[card.id] ?? const <ReviewRecordRow>[])
                  BackupReview(
                    reviewedAt: review.reviewedAt.toUtc(),
                    rating: review.rating,
                    wasCorrect: review.wasCorrect,
                    phaseBefore: review.phaseBefore,
                    elapsedDays: review.elapsedDays,
                  ),
              ],
            ),
        ],
        goals: [
          for (final goal in goals)
            BackupGoal(
              targetSet: goal.targetSet,
              targetAccuracy: goal.targetAccuracy,
              createdAt: goal.createdAt.toUtc(),
              deadline: goal.deadline.toUtc(),
              status: goal.status,
            ),
        ],
        settings: BackupSettings(
          dailyReviewCap: await _settings.getDailyReviewCap(),
          reminderTime: await _settings.getReminderTime(),
          appearanceMode: await _settings.getAppearanceMode(),
        ),
      );
    });
  }

  @override
  Future<void> replaceWith(BackupSnapshot snapshot) {
    return _db.transaction(() async {
      final items = await _db.select(_db.items).get();
      final idByKey = {for (final item in items) item.itemKey: item.id};
      // Checked before any write, so a refusal leaves the data untouched
      // without relying on the rollback.
      for (final key in snapshot.itemKeys) {
        if (!idByKey.containsKey(key)) throw UnknownItemKeyException(key);
      }

      await _db.delete(_db.reviewRecords).go();
      await _db.delete(_db.cards).go();
      await _db.delete(_db.goals).go();
      await _db
          .update(_db.items)
          .write(const ItemsCompanion(introducedAt: Value(null)));
      await _db
          .update(_db.mnemonics)
          .write(const MnemonicsCompanion(learnerText: Value(null)));

      for (final item in snapshot.introducedItems) {
        await (_db.update(_db.items)
              ..where((t) => t.id.equals(idByKey[item.key]!)))
            .write(ItemsCompanion(introducedAt: Value(item.introducedAt)));
      }
      for (final mnemonic in snapshot.learnerMnemonics) {
        await (_db.update(
          _db.mnemonics,
        )..where((t) => t.itemId.equals(idByKey[mnemonic.key]!))).write(
          MnemonicsCompanion(learnerText: Value(mnemonic.learnerText)),
        );
      }

      for (final card in snapshot.cards) {
        final scheduling = card.scheduling;
        final cardId = await _db
            .into(_db.cards)
            .insert(
              CardsCompanion.insert(
                itemId: idByKey[card.itemKey]!,
                promptType: card.promptType,
                phase: scheduling.phase,
                step: Value(scheduling.step),
                due: scheduling.due,
                stability: Value(scheduling.stability),
                difficulty: Value(scheduling.difficulty),
                lastReview: Value(scheduling.lastReview),
                reps: Value(card.reps),
                lapses: Value(card.lapses),
                consecutiveCorrect: Value(card.consecutiveCorrect),
                createdAt: card.createdAt,
              ),
            );
        await _db.batch((batch) {
          batch.insertAll(_db.reviewRecords, [
            for (final review in card.reviews)
              ReviewRecordsCompanion.insert(
                cardId: cardId,
                reviewedAt: review.reviewedAt,
                rating: review.rating,
                wasCorrect: review.wasCorrect,
                phaseBefore: review.phaseBefore,
                elapsedDays: review.elapsedDays,
              ),
          ]);
        });
      }

      for (final goal in snapshot.goals) {
        await _db
            .into(_db.goals)
            .insert(
              GoalsCompanion.insert(
                targetSet: goal.targetSet,
                targetAccuracy: goal.targetAccuracy,
                createdAt: goal.createdAt,
                deadline: goal.deadline,
                status: goal.status,
              ),
            );
      }

      await _settings.setDailyReviewCap(snapshot.settings.dailyReviewCap);
      await _settings.setReminderTime(snapshot.settings.reminderTime);
      await _settings.setAppearanceMode(snapshot.settings.appearanceMode);
    });
  }
}
