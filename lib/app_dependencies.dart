import 'dart:math';

import 'package:ippo/data/repositories/backup_file_repository.dart';
import 'package:ippo/data/repositories/backup_repository.dart';
import 'package:ippo/data/repositories/card_repository.dart';
import 'package:ippo/data/repositories/goal_repository.dart';
import 'package:ippo/data/repositories/item_repository.dart';
import 'package:ippo/data/repositories/mnemonic_repository.dart';
import 'package:ippo/data/repositories/reminder_repository.dart';
import 'package:ippo/data/repositories/review_repository.dart';
import 'package:ippo/data/repositories/settings_repository.dart';
import 'package:ippo/data/repositories/speech_repository.dart';
import 'package:ippo/data/repositories/unit_of_work.dart';
import 'package:ippo/domain/scheduling/scheduler.dart';
import 'package:ippo/domain/study_calendar.dart';
import 'package:ippo/domain/use_cases/build_choice_options.dart';
import 'package:ippo/domain/models/word_list_info.dart';
import 'package:ippo/domain/use_cases/build_review_session.dart';
import 'package:ippo/domain/use_cases/build_word_choice_options.dart';
import 'package:ippo/domain/use_cases/check_typed_answer.dart';
import 'package:ippo/domain/use_cases/complete_lesson.dart';
import 'package:ippo/domain/use_cases/export_backup.dart';
import 'package:ippo/domain/use_cases/get_goal_progress.dart';
import 'package:ippo/domain/use_cases/get_kana_status.dart';
import 'package:ippo/domain/use_cases/get_next_lesson.dart';
import 'package:ippo/domain/use_cases/get_next_word_lesson.dart';
import 'package:ippo/domain/use_cases/get_study_stats.dart';
import 'package:ippo/domain/use_cases/grade_answer.dart';
import 'package:ippo/domain/use_cases/read_backup.dart';
import 'package:ippo/domain/use_cases/reconcile_reminder.dart';
import 'package:ippo/domain/use_cases/restore_backup.dart';
import 'package:ippo/domain/use_cases/save_goal.dart';

/// The app's object graph: repositories and the use cases built on them.
///
/// Built once at startup (or with fakes in tests) and handed to
/// ViewModels through their constructors.
class AppDependencies {
  AppDependencies({
    required this.itemRepository,
    required this.mnemonicRepository,
    required this.cardRepository,
    required this.reviewRepository,
    required this.goalRepository,
    required this.settingsRepository,
    required this.speechRepository,
    required this.reminderRepository,
    required this.backupRepository,
    required this.backupFileRepository,
    required UnitOfWork unitOfWork,
    required Scheduler scheduler,
    Clock? clock,
    Random? random,
    this.wordListInfo,
  })  : clock = clock ?? DateTime.now,
        random = random ?? Random(),
        completeLesson = CompleteLesson(
          itemRepository: itemRepository,
          cardRepository: cardRepository,
          unitOfWork: unitOfWork,
          scheduler: scheduler,
        ),
        gradeAnswer = GradeAnswer(
          cardRepository: cardRepository,
          reviewRepository: reviewRepository,
          unitOfWork: unitOfWork,
          scheduler: scheduler,
        ),
        saveGoal = SaveGoal(goalRepository: goalRepository),
        exportBackup = ExportBackup(backupRepository: backupRepository),
        readBackup = ReadBackup(
          backupRepository: backupRepository,
          itemRepository: itemRepository,
        ),
        reconcileReminder = ReconcileReminder(
          settingsRepository: settingsRepository,
          reminderRepository: reminderRepository,
        ),
        restoreBackup = RestoreBackup(
          backupRepository: backupRepository,
          reconcileReminder: ReconcileReminder(
            settingsRepository: settingsRepository,
            reminderRepository: reminderRepository,
          ),
        );

  final ItemRepository itemRepository;
  final MnemonicRepository mnemonicRepository;
  final CardRepository cardRepository;
  final ReviewRepository reviewRepository;
  final GoalRepository goalRepository;
  final SettingsRepository settingsRepository;
  final SpeechRepository speechRepository;
  final ReminderRepository reminderRepository;
  final BackupRepository backupRepository;
  final BackupFileRepository backupFileRepository;

  /// The bundled word list; null when no list was loaded, as in tests
  /// that do not need one.
  final WordListInfo? wordListInfo;

  final Clock clock;
  final Random random;

  final CompleteLesson completeLesson;
  final GradeAnswer gradeAnswer;
  final SaveGoal saveGoal;
  final ExportBackup exportBackup;
  final ReadBackup readBackup;
  final ReconcileReminder reconcileReminder;
  final RestoreBackup restoreBackup;

  final GetNextLesson getNextLesson = const GetNextLesson();
  final GetNextWordLesson getNextWordLesson = const GetNextWordLesson();
  final BuildChoiceOptions buildChoiceOptions = const BuildChoiceOptions();
  final BuildWordChoiceOptions buildWordChoiceOptions =
      const BuildWordChoiceOptions();
  final BuildReviewSession buildReviewSession = const BuildReviewSession();
  final CheckTypedAnswer checkTypedAnswer = const CheckTypedAnswer();
  final GetGoalProgress getGoalProgress = const GetGoalProgress();
  final GetKanaStatus getKanaStatus = const GetKanaStatus();
  final GetStudyStats getStudyStats = const GetStudyStats();
}
