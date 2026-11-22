import 'dart:async';

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
import 'package:ippo/domain/models/appearance_mode.dart';
import 'package:ippo/domain/models/backup_snapshot.dart';
import 'package:ippo/domain/models/goal.dart';
import 'package:ippo/domain/models/item.dart';
import 'package:ippo/domain/models/mnemonic.dart';
import 'package:ippo/domain/models/rating.dart';
import 'package:ippo/domain/models/reminder_time.dart';
import 'package:ippo/domain/models/review_card.dart';
import 'package:ippo/domain/models/review_record.dart';
import 'package:ippo/domain/models/scheduling_state.dart';
import 'package:ippo/domain/models/seed_item.dart';
import 'package:ippo/domain/models/speech_speed.dart';

/// Emits the current value on listen, then every later change.
class _Observable<T> {
  _Observable(this._read);

  final T Function() _read;
  final _changes = StreamController<void>.broadcast();

  void notify() => _changes.add(null);

  Stream<T> get stream async* {
    yield _read();
    await for (final _ in _changes.stream) {
      yield _read();
    }
  }
}

class FakeItemRepository implements ItemRepository {
  FakeItemRepository([List<Item> items = const []]) : _items = [...items];

  final List<Item> _items;
  final Map<int, String> seededMnemonics = {};
  late final _observable = _Observable<List<Item>>(_sorted);

  List<Item> _sorted() =>
      [..._items]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  @override
  Stream<List<Item>> getItemsStream() => _observable.stream;

  @override
  Future<List<Item>> getItems() async => _sorted();

  @override
  Future<Item?> getItem(int id) async =>
      _items.where((item) => item.id == id).firstOrNull;

  @override
  Future<void> syncSeedItems(List<SeedItem> seedItems) async {
    for (final seed in seedItems) {
      final index = _items.indexWhere((item) => item.key == seed.key);
      if (index < 0) {
        final id = _items.length + 1;
        _items.add(
          Item(
            id: id,
            kind: seed.kind,
            key: seed.key,
            sortOrder: seed.sortOrder,
            payload: seed.payload,
          ),
        );
        final mnemonic = seed.defaultMnemonic;
        if (mnemonic != null) seededMnemonics[id] = mnemonic;
      } else {
        final item = _items[index];
        _items[index] = Item(
          id: item.id,
          kind: item.kind,
          key: item.key,
          sortOrder: seed.sortOrder,
          payload: seed.payload,
          introducedAt: item.introducedAt,
        );
        final mnemonic = seed.defaultMnemonic;
        if (mnemonic != null) seededMnemonics[item.id] = mnemonic;
      }
    }
    _observable.notify();
  }

  @override
  Future<void> markIntroduced(List<int> itemIds, DateTime at) async {
    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (itemIds.contains(item.id)) {
        _items[i] = Item(
          id: item.id,
          kind: item.kind,
          key: item.key,
          sortOrder: item.sortOrder,
          payload: item.payload,
          introducedAt: at,
        );
      }
    }
    _observable.notify();
  }
}

class FakeMnemonicRepository implements MnemonicRepository {
  FakeMnemonicRepository([Map<int, String> defaults = const {}])
      : _mnemonics = {
          for (final entry in defaults.entries)
            entry.key: Mnemonic(itemId: entry.key, defaultText: entry.value),
        };

  final Map<int, Mnemonic> _mnemonics;
  final _changes = StreamController<void>.broadcast();

  Mnemonic _read(int itemId) =>
      _mnemonics[itemId] ??
      Mnemonic(itemId: itemId, defaultText: 'mnemonic $itemId');

  @override
  Stream<Mnemonic> getMnemonicStream(int itemId) async* {
    yield _read(itemId);
    await for (final _ in _changes.stream) {
      yield _read(itemId);
    }
  }

  @override
  Future<Mnemonic> getMnemonic(int itemId) async => _read(itemId);

  @override
  Future<void> saveLearnerText(int itemId, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(text, 'text', 'A mnemonic cannot be empty');
    }
    _mnemonics[itemId] = Mnemonic(
      itemId: itemId,
      defaultText: _read(itemId).defaultText,
      learnerText: trimmed,
    );
    _changes.add(null);
  }

  @override
  Future<void> restoreDefault(int itemId) async {
    _mnemonics[itemId] =
        Mnemonic(itemId: itemId, defaultText: _read(itemId).defaultText);
    _changes.add(null);
  }
}

class FakeCardRepository implements CardRepository {
  FakeCardRepository([List<ReviewCard> cards = const []])
      : _cards = [...cards];

  final List<ReviewCard> _cards;
  late final _observable = _Observable<List<ReviewCard>>(() => [..._cards]);

  @override
  Stream<List<ReviewCard>> getCardsStream() => _observable.stream;

  @override
  Future<List<ReviewCard>> getCards() async => [..._cards];

  @override
  Future<ReviewCard> createCard({
    required int itemId,
    required PromptType promptType,
    required SchedulingState scheduling,
    required DateTime createdAt,
  }) async {
    final existing = _cards
        .where((c) => c.itemId == itemId && c.promptType == promptType)
        .firstOrNull;
    if (existing != null) return existing;
    final nextId =
        _cards.fold<int>(0, (max, c) => c.id > max ? c.id : max) + 1;
    final card = ReviewCard(
      id: nextId,
      itemId: itemId,
      promptType: promptType,
      scheduling: scheduling,
      createdAt: createdAt,
    );
    _cards.add(card);
    _observable.notify();
    return card;
  }

  @override
  Future<void> updateCard(ReviewCard card) async {
    final index = _cards.indexWhere((c) => c.id == card.id);
    _cards[index] = card;
    _observable.notify();
  }
}

class FakeReviewRepository implements ReviewRepository {
  FakeReviewRepository([List<ReviewRecord> records = const []])
      : _records = [...records];

  final List<ReviewRecord> _records;
  late final _observable =
      _Observable<List<ReviewRecord>>(() => [..._records]);

  @override
  Stream<List<ReviewRecord>> getReviewsStream() => _observable.stream;

  @override
  Future<List<ReviewRecord>> getReviews() async => [..._records];

  @override
  Future<void> addReview({
    required int cardId,
    required DateTime reviewedAt,
    required Rating rating,
    required bool wasCorrect,
    required CardPhase phaseBefore,
    required int elapsedDays,
  }) async {
    _records.add(
      ReviewRecord(
        id: _records.length + 1,
        cardId: cardId,
        reviewedAt: reviewedAt,
        rating: rating,
        wasCorrect: wasCorrect,
        phaseBefore: phaseBefore,
        elapsedDays: elapsedDays,
      ),
    );
    _observable.notify();
  }
}

class FakeGoalRepository implements GoalRepository {
  FakeGoalRepository([Goal? goal]) : _goals = [?goal];

  final List<Goal> _goals;
  late final _observable = _Observable<Goal?>(() => _goals.lastOrNull);

  @override
  Stream<Goal?> getCurrentGoalStream() => _observable.stream;

  @override
  Future<Goal?> getCurrentGoal() async => _goals.lastOrNull;

  @override
  Future<Goal> createGoal({
    required GoalTargetSet targetSet,
    required double targetAccuracy,
    required DateTime createdAt,
    required DateTime deadline,
  }) async {
    final goal = Goal(
      id: _goals.length + 1,
      targetSet: targetSet,
      targetAccuracy: targetAccuracy,
      createdAt: createdAt,
      deadline: deadline,
    );
    _goals.add(goal);
    _observable.notify();
    return goal;
  }

  @override
  Future<void> updateGoal(Goal goal) async {
    final index = _goals.indexWhere((g) => g.id == goal.id);
    _goals[index] = goal;
    _observable.notify();
  }
}

class FakeSettingsRepository implements SettingsRepository {
  int dailyReviewCap = SettingsRepository.defaultDailyReviewCap;
  ReminderTime? reminderTime;
  bool voiceNoticeShown = false;

  @override
  Future<int> getDailyReviewCap() async => dailyReviewCap;

  @override
  Future<void> setDailyReviewCap(int cap) async {
    if (cap < 1) {
      throw ArgumentError.value(cap, 'cap', 'The cap must be at least 1');
    }
    dailyReviewCap = cap;
  }

  @override
  Future<ReminderTime?> getReminderTime() async => reminderTime;

  @override
  Future<void> setReminderTime(ReminderTime? time) async {
    reminderTime = time;
  }

  @override
  Future<bool> isVoiceNoticeShown() async => voiceNoticeShown;

  @override
  Future<void> setVoiceNoticeShown() async {
    voiceNoticeShown = true;
  }

  AppearanceMode appearanceMode = AppearanceMode.automatic;
  final _appearanceChanges = StreamController<AppearanceMode>.broadcast();

  @override
  Stream<AppearanceMode> getAppearanceModeStream() async* {
    yield appearanceMode;
    yield* _appearanceChanges.stream;
  }

  @override
  Future<AppearanceMode> getAppearanceMode() async => appearanceMode;

  @override
  Future<void> setAppearanceMode(AppearanceMode mode) async {
    appearanceMode = mode;
    _appearanceChanges.add(mode);
  }

  SpeechSpeed speechSpeed = SpeechSpeed.fallback;

  @override
  Future<SpeechSpeed> getSpeechSpeed() async => speechSpeed;

  @override
  Future<void> setSpeechSpeed(SpeechSpeed speed) async {
    speechSpeed = speed;
  }

  DateTime? lastExportAt;

  @override
  Future<DateTime?> getLastExportAt() async => lastExportAt;

  @override
  Future<void> setLastExportAt(DateTime time) async {
    lastExportAt = time;
  }
}

class FakeSpeechRepository implements SpeechRepository {
  FakeSpeechRepository({this.japaneseVoiceAvailable = true});

  bool japaneseVoiceAvailable;

  /// Every text passed to [speak], in order.
  final List<String> spoken = [];
  int stopCount = 0;

  @override
  Future<bool> isJapaneseVoiceAvailable() async => japaneseVoiceAvailable;

  @override
  Future<void> speak(String text) async {
    spoken.add(text);
  }

  @override
  Future<void> stop() async {
    stopCount++;
  }
}

class FakeReminderRepository implements ReminderRepository {
  FakeReminderRepository({this.permissionGranted = true});

  bool permissionGranted;
  ReminderTime? scheduled;

  @override
  Future<bool> enableReminder(ReminderTime time) async {
    permissionRequests++;
    if (!permissionGranted) return false;
    scheduled = time;
    return true;
  }

  @override
  Future<void> disableReminder() async {
    scheduled = null;
  }

  /// How often permission was asked for.
  int permissionRequests = 0;

  @override
  Future<bool> rescheduleIfPermitted(ReminderTime time) async {
    if (!permissionGranted) return false;
    scheduled = time;
    return true;
  }
}

/// Holds one snapshot as "the data on the phone".
class FakeBackupRepository implements BackupRepository {
  FakeBackupRepository([BackupSnapshot? current])
      : current = current ?? BackupSnapshot(exportedAt: DateTime.utc(2026));

  BackupSnapshot current;

  /// Every snapshot passed to [replaceWith], in order.
  final List<BackupSnapshot> replaced = [];

  /// Makes [replaceWith] fail, as a database error would.
  bool failOnReplace = false;

  @override
  Future<BackupSnapshot> readSnapshot(DateTime now) async {
    return BackupSnapshot(
      exportedAt: now.toUtc(),
      introducedItems: current.introducedItems,
      learnerMnemonics: current.learnerMnemonics,
      cards: current.cards,
      goals: current.goals,
      settings: current.settings,
    );
  }

  @override
  Future<void> replaceWith(BackupSnapshot snapshot) async {
    if (failOnReplace) throw StateError('replace failed');
    replaced.add(snapshot);
    current = snapshot;
  }
}

/// Stands in for the system's save and open dialogs.
class FakeBackupFileRepository implements BackupFileRepository {
  /// Whether the learner picks a location when saving.
  bool acceptSave = true;

  /// The text of the file the learner picks; null means they cancel.
  String? fileToPick;

  /// Makes [pickFile] report a file that is too large.
  bool pickTooLarge = false;

  /// What was saved, by file name.
  final Map<String, String> saved = {};

  @override
  Future<bool> saveFile({
    required String suggestedName,
    required String text,
  }) async {
    if (!acceptSave) return false;
    saved[suggestedName] = text;
    return true;
  }

  @override
  Future<String?> pickFile() async {
    if (pickTooLarge) throw const BackupFileTooLargeException();
    return fileToPick;
  }
}

/// Runs the action directly; fakes have nothing to roll back.
class FakeUnitOfWork implements UnitOfWork {
  @override
  Future<T> run<T>(Future<T> Function() action) => action();
}
