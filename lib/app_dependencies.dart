import 'dart:math';

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
import 'package:ippo/domain/use_cases/build_review_session.dart';
import 'package:ippo/domain/use_cases/check_typed_answer.dart';
import 'package:ippo/domain/use_cases/complete_lesson.dart';
import 'package:ippo/domain/use_cases/get_goal_progress.dart';
import 'package:ippo/domain/use_cases/get_kana_status.dart';
import 'package:ippo/domain/use_cases/get_next_lesson.dart';
import 'package:ippo/domain/use_cases/get_study_stats.dart';
import 'package:ippo/domain/use_cases/grade_answer.dart';
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
    required UnitOfWork unitOfWork,
    required Scheduler scheduler,
    Clock? clock,
    Random? random,
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
        saveGoal = SaveGoal(goalRepository: goalRepository);

  final ItemRepository itemRepository;
  final MnemonicRepository mnemonicRepository;
  final CardRepository cardRepository;
  final ReviewRepository reviewRepository;
  final GoalRepository goalRepository;
  final SettingsRepository settingsRepository;
  final SpeechRepository speechRepository;
  final ReminderRepository reminderRepository;

  final Clock clock;
  final Random random;

  final CompleteLesson completeLesson;
  final GradeAnswer gradeAnswer;
  final SaveGoal saveGoal;

  final GetNextLesson getNextLesson = const GetNextLesson();
  final BuildChoiceOptions buildChoiceOptions = const BuildChoiceOptions();
  final BuildReviewSession buildReviewSession = const BuildReviewSession();
  final CheckTypedAnswer checkTypedAnswer = const CheckTypedAnswer();
  final GetGoalProgress getGoalProgress = const GetGoalProgress();
  final GetKanaStatus getKanaStatus = const GetKanaStatus();
  final GetStudyStats getStudyStats = const GetStudyStats();
}
