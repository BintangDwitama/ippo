import 'dart:math';

import 'package:ippo/app_dependencies.dart';
import 'package:ippo/domain/models/goal.dart';
import 'package:ippo/domain/models/item.dart';
import 'package:ippo/domain/models/review_card.dart';
import 'package:ippo/domain/models/review_record.dart';

import '../fakes/fake_repositories.dart';
import '../fakes/fake_scheduler.dart';

/// An [AppDependencies] built entirely from fakes, with the fakes exposed
/// so tests can inspect and change them.
class FakeDependencies {
  FakeDependencies({
    List<Item> items = const [],
    List<ReviewCard> cards = const [],
    List<ReviewRecord> reviews = const [],
    Goal? goal,
    DateTime? now,
    bool japaneseVoiceAvailable = true,
    bool notificationPermissionGranted = true,
  })  : now = now ?? DateTime(2026, 1, 10, 9),
        items = FakeItemRepository(items),
        cards = FakeCardRepository(cards),
        reviews = FakeReviewRepository(reviews),
        goals = FakeGoalRepository(goal),
        speech =
            FakeSpeechRepository(japaneseVoiceAvailable: japaneseVoiceAvailable),
        reminders = FakeReminderRepository(
          permissionGranted: notificationPermissionGranted,
        );

  /// The time the fake clock reports; tests may change it.
  DateTime now;

  final FakeItemRepository items;
  final FakeCardRepository cards;
  final FakeReviewRepository reviews;
  final FakeGoalRepository goals;
  final FakeSpeechRepository speech;
  final FakeReminderRepository reminders;
  final FakeMnemonicRepository mnemonics = FakeMnemonicRepository();
  final FakeSettingsRepository settings = FakeSettingsRepository();
  final FakeBackupRepository backups = FakeBackupRepository();
  final FakeBackupFileRepository backupFiles = FakeBackupFileRepository();
  final FakeScheduler scheduler = FakeScheduler();

  late final AppDependencies app = AppDependencies(
    itemRepository: items,
    mnemonicRepository: mnemonics,
    cardRepository: cards,
    reviewRepository: reviews,
    goalRepository: goals,
    settingsRepository: settings,
    speechRepository: speech,
    reminderRepository: reminders,
    backupRepository: backups,
    backupFileRepository: backupFiles,
    unitOfWork: FakeUnitOfWork(),
    scheduler: scheduler,
    clock: () => now,
    random: Random(42),
  );
}
