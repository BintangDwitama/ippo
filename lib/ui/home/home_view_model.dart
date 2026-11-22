import 'dart:async';
import 'dart:math';

import 'package:ippo/app_dependencies.dart';
import 'package:ippo/data/repositories/settings_repository.dart';
import 'package:ippo/domain/models/goal.dart';
import 'package:ippo/domain/models/item.dart';
import 'package:ippo/domain/models/review_card.dart';
import 'package:ippo/domain/models/review_record.dart';
import 'package:ippo/domain/use_cases/save_goal.dart';
import 'package:ippo/ui/core/view_model.dart';
import 'package:ippo/ui/home/home_ui_state.dart';

class HomeViewModel extends ViewModel {
  HomeViewModel(this._deps) {
    _subscriptions = [
      _deps.itemRepository.getItemsStream().listen((items) {
        _items = items;
        _recompute();
      }),
      _deps.cardRepository.getCardsStream().listen((cards) {
        _cards = cards;
        _recompute();
      }),
      _deps.reviewRepository.getReviewsStream().listen((reviews) {
        _reviews = reviews;
        _recompute();
      }),
      _deps.goalRepository.getCurrentGoalStream().listen((goal) {
        _goal = goal;
        _goalLoaded = true;
        _recompute();
      }),
    ];
    unawaited(refresh());
  }

  final AppDependencies _deps;
  late final List<StreamSubscription<void>> _subscriptions;

  List<Item>? _items;
  List<ReviewCard>? _cards;
  List<ReviewRecord>? _reviews;
  Goal? _goal;
  bool _goalLoaded = false;
  int _dailyCap = SettingsRepository.defaultDailyReviewCap;
  bool? _voiceAvailable;
  bool _voiceNoticeShown = true;

  HomeUiState _uiState = const HomeUiState();
  HomeUiState get uiState => _uiState;

  /// Reloads settings and recalculates everything that depends on the
  /// current time. Call when the screen becomes visible again.
  Future<void> refresh() async {
    _dailyCap = await _deps.settingsRepository.getDailyReviewCap();
    _voiceAvailable = await _deps.speechRepository.isJapaneseVoiceAvailable();
    _voiceNoticeShown = await _deps.settingsRepository.isVoiceNoticeShown();
    _recompute();
  }

  /// Starts the suggested first goal.
  Future<void> acceptPresetGoal() async {
    await _deps.saveGoal.create(
      targetSet: SaveGoal.presetTargetSet,
      targetAccuracy: SaveGoal.presetAccuracy,
      deadlineDays: SaveGoal.presetDeadlineDays,
      now: _deps.clock(),
    );
  }

  Future<void> dismissVoiceNotice() async {
    await _deps.settingsRepository.setVoiceNoticeShown();
    _voiceNoticeShown = true;
    _recompute();
  }

  void _recompute() {
    final items = _items;
    final cards = _cards;
    final reviews = _reviews;
    final voiceAvailable = _voiceAvailable;
    if (items == null ||
        cards == null ||
        reviews == null ||
        voiceAvailable == null ||
        !_goalLoaded) {
      return;
    }
    final now = _deps.clock();
    final goal = _goal;

    final progress = goal == null
        ? null
        : _deps.getGoalProgress(
            goal: goal,
            items: items,
            cards: cards,
            reviews: reviews,
            now: now,
          );
    if (goal != null && progress != null && progress.status != goal.status) {
      // The goal was just achieved or missed; the stream will emit again.
      unawaited(
        _deps.goalRepository.updateGoal(
          Goal(
            id: goal.id,
            targetSet: goal.targetSet,
            targetAccuracy: goal.targetAccuracy,
            createdAt: goal.createdAt,
            deadline: goal.deadline,
            status: progress.status,
          ),
        ),
      );
    }

    final remainingCap = _deps.getStudyStats.remainingReviewCap(
      dailyCap: _dailyCap,
      reviews: reviews,
      now: now,
    );
    List<ReviewCard> sessionWithCap(int cap) => _deps.buildReviewSession(
          cards: cards,
          now: now,
          remainingCap: cap,
          voiceAvailable: voiceAvailable,
          random: Random(0),
        );
    final dueCount = sessionWithCap(remainingCap).length;
    final dueIgnoringCap = sessionWithCap(cards.length).length;

    final upcoming = cards
        .where((card) => !card.isDueAt(now))
        .map((card) => card.due)
        .toList()
      ..sort();

    _uiState = HomeUiState(
      isLoading: false,
      goal: goal,
      progress: progress,
      dueCount: dueCount,
      nextLessonKana: [
        for (final item
            in _deps.getNextLesson(items: items, goal: goal, now: now))
          item.kana.character,
      ],
      nextLessonWords: [
        for (final item in _deps.getNextWordLesson(
          items: items,
          now: now,
          currentKeys: _deps.wordListInfo?.keys,
        ))
          item.word.reading,
      ],
      streak: _deps.getStudyStats.streak(
        items: items,
        reviews: reviews,
        now: now,
      ),
      nextDue: dueCount == 0 && upcoming.isNotEmpty ? upcoming.first : null,
      isReviewCapReached: dueCount == 0 && dueIgnoringCap > 0,
      showVoiceNotice: !voiceAvailable && !_voiceNoticeShown,
    );
    notify();
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }
}
