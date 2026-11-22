import 'dart:async';

import 'package:ippo/app_dependencies.dart';
import 'package:ippo/domain/models/item.dart';
import 'package:ippo/ui/core/view_model.dart';
import 'package:ippo/ui/word_lesson/word_lesson_ui_state.dart';

class WordLessonViewModel extends ViewModel {
  WordLessonViewModel(this._deps) {
    unawaited(_load());
  }

  final AppDependencies _deps;

  List<Item> _allItems = const [];
  List<Item> _lesson = const [];
  bool _voiceAvailable = true;
  int _presentingIndex = 0;
  bool _isCompleting = false;

  /// Words still to be answered correctly in the check; the first is
  /// current.
  List<Item> _checkQueue = [];

  WordLessonUiState _uiState = const WordLessonLoading();
  WordLessonUiState get uiState => _uiState;

  Future<void> _load() async {
    _allItems = await _deps.itemRepository.getItems();
    _voiceAvailable = await _deps.speechRepository.isJapaneseVoiceAvailable();
    _lesson = _deps.getNextWordLesson(
      items: _allItems,
      now: _deps.clock(),
      currentKeys: _deps.wordListInfo?.keys,
    );
    if (_lesson.isEmpty) {
      _setState(const WordLessonUnavailable());
      return;
    }
    _present(0);
  }

  /// Moves to the next new word, or starts the check after the last one.
  void showNext() {
    if (_uiState is! WordLessonPresenting) return;
    if (_presentingIndex + 1 < _lesson.length) {
      _present(_presentingIndex + 1);
    } else {
      _checkQueue = [..._lesson]..shuffle(_deps.random);
      _askNext();
    }
  }

  /// Goes back to the word before the one on screen.
  void showPrevious() {
    if (_uiState is! WordLessonPresenting || _presentingIndex == 0) return;
    _present(_presentingIndex - 1);
  }

  void replaySound() {
    final state = _uiState;
    final item = switch (state) {
      WordLessonPresenting() => state.item,
      WordLessonFeedback() => state.item,
      _ => null,
    };
    if (item != null) _speak(item);
  }

  /// Answers the check with the meaning of [option].
  Future<void> answer(Item option) async {
    final state = _uiState;
    if (state is! WordLessonCheck || _isCompleting) return;
    if (option.id != state.item.id) {
      _setState(
        WordLessonFeedback(
          item: state.item,
          chosen: option,
          voiceAvailable: _voiceAvailable,
        ),
      );
      _speak(state.item);
      return;
    }
    _checkQueue.removeAt(0);
    if (_checkQueue.isNotEmpty) {
      _askNext();
      return;
    }
    // Ignore a second tap while the lesson is being saved.
    _isCompleting = true;
    await _deps.completeLesson(items: _lesson, now: _deps.clock());
    _setState(WordLessonComplete(items: _lesson));
  }

  /// After a wrong answer: the word goes to the back of the check.
  void continueAfterFeedback() {
    if (_uiState is! WordLessonFeedback) return;
    _checkQueue.add(_checkQueue.removeAt(0));
    _askNext();
  }

  void _present(int index) {
    _presentingIndex = index;
    final item = _lesson[index];
    _setState(
      WordLessonPresenting(
        item: item,
        index: index,
        total: _lesson.length,
        voiceAvailable: _voiceAvailable,
      ),
    );
    _speak(item);
  }

  void _askNext() {
    final item = _checkQueue.first;
    _setState(
      WordLessonCheck(
        item: item,
        options: _deps.buildWordChoiceOptions(
          correct: item,
          allItems: _allItems,
          random: _deps.random,
          alsoKnown: _lesson,
        ),
        answered: _lesson.length - _checkQueue.length,
        total: _lesson.length,
      ),
    );
  }

  void _speak(Item item) {
    if (!_voiceAvailable) return;
    // The reading, never the written form: a voice can misread kanji.
    unawaited(_deps.speechRepository.speak(item.word.reading));
  }

  void _setState(WordLessonUiState state) {
    _uiState = state;
    notify();
  }

  @override
  void dispose() {
    unawaited(_deps.speechRepository.stop());
    super.dispose();
  }
}
