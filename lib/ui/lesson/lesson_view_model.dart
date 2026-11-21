import 'dart:async';

import 'package:ippo/app_dependencies.dart';
import 'package:ippo/domain/models/item.dart';
import 'package:ippo/domain/models/mnemonic.dart';
import 'package:ippo/ui/core/view_model.dart';
import 'package:ippo/ui/lesson/lesson_ui_state.dart';

class LessonViewModel extends ViewModel {
  LessonViewModel(this._deps) {
    unawaited(_load());
  }

  final AppDependencies _deps;

  List<Item> _allItems = const [];
  List<Item> _lesson = const [];
  Map<int, Mnemonic> _mnemonics = const {};
  int _presentingIndex = 0;

  /// Kana still to be answered correctly in the quiz; the first is current.
  List<Item> _quizQueue = [];

  LessonUiState _uiState = const LessonLoading();
  LessonUiState get uiState => _uiState;

  Future<void> _load() async {
    _allItems = await _deps.itemRepository.getItems();
    final goal = await _deps.goalRepository.getCurrentGoal();
    _lesson = _deps.getNextLesson(
      items: _allItems,
      goal: goal,
      now: _deps.clock(),
    );
    if (_lesson.isEmpty) {
      _setState(const LessonUnavailable());
      return;
    }
    _mnemonics = {
      for (final item in _lesson)
        item.id: await _deps.mnemonicRepository.getMnemonic(item.id),
    };
    _present(0);
  }

  /// Moves to the next new kana, or starts the quiz after the last one.
  void showNext() {
    if (_uiState is! LessonPresenting) return;
    if (_presentingIndex + 1 < _lesson.length) {
      _present(_presentingIndex + 1);
    } else if (_quizzable.isEmpty) {
      unawaited(_complete());
    } else {
      _quizQueue = [..._quizzable]..shuffle(_deps.random);
      _askNext();
    }
  }

  /// The kana of the lesson that can be asked about. Marks cannot: they
  /// have no reading.
  List<Item> get _quizzable => [
    for (final item in _lesson)
      if (!item.kana.isMark) item,
  ];

  Future<void> _complete() async {
    await _deps.completeLesson(items: _lesson, now: _deps.clock());
    _setState(
      LessonComplete(items: _lesson, hasReviewCards: _quizzable.isNotEmpty),
    );
  }

  void replaySound() {
    final state = _uiState;
    final item = switch (state) {
      LessonPresenting() => state.item,
      LessonFeedback() => state.item,
      _ => null,
    };
    if (item != null) _speak(item);
  }

  Future<void> answer(Item option) async {
    final state = _uiState;
    if (state is! LessonQuiz) return;
    if (option.id != state.item.id) {
      _setState(
        LessonFeedback(
          item: state.item,
          mnemonic: _mnemonics[state.item.id]!,
          chosen: option,
        ),
      );
      _speak(state.item);
      return;
    }
    _quizQueue.removeAt(0);
    if (_quizQueue.isNotEmpty) {
      _askNext();
      return;
    }
    await _complete();
  }

  /// After a wrong answer: the kana goes to the back of the quiz.
  void continueAfterFeedback() {
    if (_uiState is! LessonFeedback) return;
    _quizQueue.add(_quizQueue.removeAt(0));
    _askNext();
  }

  void _present(int index) {
    _presentingIndex = index;
    final item = _lesson[index];
    _setState(
      LessonPresenting(
        item: item,
        mnemonic: _mnemonics[item.id]!,
        index: index,
        total: _lesson.length,
        hasQuiz: _quizzable.isNotEmpty,
      ),
    );
    _speak(item);
  }

  void _askNext() {
    final item = _quizQueue.first;
    _setState(
      LessonQuiz(
        item: item,
        options: _deps.buildChoiceOptions(
          correct: item,
          allItems: _allItems,
          random: _deps.random,
          preferred: _lesson,
        ),
        answered: _quizzable.length - _quizQueue.length,
        total: _quizzable.length,
      ),
    );
  }

  void _speak(Item item) {
    unawaited(_deps.speechRepository.speak(item.kana.spoken));
  }

  void _setState(LessonUiState state) {
    _uiState = state;
    notify();
  }

  @override
  void dispose() {
    unawaited(_deps.speechRepository.stop());
    super.dispose();
  }
}
