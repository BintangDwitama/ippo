import 'dart:async';

import 'package:ippo/app_dependencies.dart';
import 'package:ippo/domain/models/item.dart';
import 'package:ippo/domain/models/review_card.dart';
import 'package:ippo/domain/use_cases/review_session.dart';
import 'package:ippo/ui/core/view_model.dart';
import 'package:ippo/ui/review/review_ui_state.dart';

class ReviewViewModel extends ViewModel {
  ReviewViewModel(this._deps) {
    unawaited(_load());
  }

  final AppDependencies _deps;

  List<Item> _allItems = const [];
  Map<int, Item> _itemsById = const {};
  late ReviewSession _session;
  bool _isAnswering = false;
  bool _voiceAvailable = true;

  ReviewUiState _uiState = const ReviewLoading();
  ReviewUiState get uiState => _uiState;

  Future<void> _load() async {
    _allItems = await _deps.itemRepository.getItems();
    _itemsById = {for (final item in _allItems) item.id: item};
    final cards = await _deps.cardRepository.getCards();
    final reviews = await _deps.reviewRepository.getReviews();
    final now = _deps.clock();
    final remainingCap = _deps.getStudyStats.remainingReviewCap(
      dailyCap: await _deps.settingsRepository.getDailyReviewCap(),
      reviews: reviews,
      now: now,
    );
    final voiceAvailable =
        await _deps.speechRepository.isJapaneseVoiceAvailable();
    _voiceAvailable = voiceAvailable;

    final sessionCards = _deps.buildReviewSession(
      cards: cards,
      now: now,
      remainingCap: remainingCap,
      voiceAvailable: voiceAvailable,
      random: _deps.random,
    );
    _session = ReviewSession(sessionCards);

    if (sessionCards.isEmpty) {
      final anyDue = cards.any(
        (card) =>
            card.isDueAt(now) &&
            (voiceAvailable || !card.promptType.needsAudio),
      );
      final upcoming = cards
          .where((card) => !card.isDueAt(now))
          .map((card) => card.due)
          .toList()
        ..sort();
      _setState(
        ReviewEmpty(
          nextDue: upcoming.isEmpty ? null : upcoming.first,
          isCapReached: anyDue && remainingCap == 0,
        ),
      );
      return;
    }
    _askCurrent();
  }

  /// Answers a multiple-choice question with [option].
  Future<void> answerChoice(Item option) async {
    final state = _uiState;
    if (state is! ReviewQuestion || state.promptType.isTyped) return;
    final shown = switch (state.promptType) {
      PromptType.soundToCharChoice => option.kana.character,
      PromptType.wordToMeaningChoice => option.word.meaningText,
      PromptType.meaningToWordChoice => option.word.reading,
      PromptType.charToSoundChoice ||
      PromptType.charToSoundTyped =>
        option.kana.romaji,
    };
    await _answer(wasCorrect: option.id == state.item.id, givenAnswer: shown);
  }

  /// Answers a typed question with [input].
  Future<void> answerTyped(String input) async {
    final state = _uiState;
    if (state is! ReviewQuestion || !state.promptType.isTyped) return;
    if (input.trim().isEmpty) return;
    await _answer(
      wasCorrect: _deps.checkTypedAnswer(state.item.kana, input),
      givenAnswer: input.trim(),
    );
  }

  void replaySound() {
    final state = _uiState;
    final item = switch (state) {
      // A word question is never read out: the sound would give away a
      // word shown as an option.
      ReviewQuestion() => state.item.isKana ? state.item : null,
      ReviewFeedback() => state.item,
      _ => null,
    };
    if (item != null) _speak(item);
  }

  void continueAfterFeedback() {
    if (_uiState is! ReviewFeedback) return;
    _askCurrent();
  }

  Future<void> _answer({
    required bool wasCorrect,
    required String givenAnswer,
  }) async {
    // Ignore a second tap while the first answer is being saved.
    if (_isAnswering) return;
    _isAnswering = true;
    try {
      final card = _session.current!;
      final item = _itemsById[card.itemId]!;
      // Only the first attempt is graded; repeats are practice.
      if (!_session.isRepeat) {
        await _deps.gradeAnswer(
          card: card,
          wasCorrect: wasCorrect,
          now: _deps.clock(),
        );
      }
      _session.recordAnswer(wasCorrect: wasCorrect);

      if (item.isWord) {
        // Right or wrong, the word is shown in full and spoken: seeing
        // and hearing it again is part of learning it.
        _setState(
          ReviewFeedback(
            item: item,
            promptType: card.promptType,
            givenAnswer: givenAnswer,
            wasCorrect: wasCorrect,
            voiceAvailable: _voiceAvailable,
          ),
        );
        _speak(item);
      } else if (wasCorrect) {
        _askCurrent();
      } else {
        _setState(
          ReviewFeedback(
            item: item,
            mnemonic: await _deps.mnemonicRepository.getMnemonic(item.id),
            promptType: card.promptType,
            givenAnswer: givenAnswer,
          ),
        );
        _speak(item);
      }
    } finally {
      _isAnswering = false;
    }
  }

  void _askCurrent() {
    final card = _session.current;
    if (card == null) {
      _setState(
        ReviewSummary(
          reviewed: _session.reviewedCount,
          accuracy: _session.accuracy,
        ),
      );
      return;
    }
    final item = _itemsById[card.itemId]!;
    _setState(
      ReviewQuestion(
        item: item,
        promptType: card.promptType,
        options: card.promptType.isTyped
            ? const []
            : item.isWord
                ? _deps.buildWordChoiceOptions(
                    correct: item,
                    allItems: _allItems,
                    random: _deps.random,
                  )
                : _deps.buildChoiceOptions(
                    correct: item,
                    allItems: _allItems,
                    random: _deps.random,
                  ),
        reviewed: _session.reviewedCount,
        total: _session.total,
        isRepeat: _session.isRepeat,
      ),
    );
    if (card.promptType.needsAudio) _speak(item);
  }

  void _speak(Item item) {
    if (item.isWord) {
      if (!_voiceAvailable) return;
      // The reading, never the written form: a voice can misread kanji.
      unawaited(_deps.speechRepository.speak(item.word.reading));
      return;
    }
    unawaited(_deps.speechRepository.speak(item.kana.spoken));
  }

  void _setState(ReviewUiState state) {
    _uiState = state;
    notify();
  }

  @override
  void dispose() {
    unawaited(_deps.speechRepository.stop());
    super.dispose();
  }
}
