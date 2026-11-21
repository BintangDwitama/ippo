import 'package:flutter_test/flutter_test.dart';
import 'package:ippo/domain/models/goal.dart';
import 'package:ippo/domain/models/item.dart';
import 'package:ippo/domain/models/kana_status.dart';
import 'package:ippo/domain/models/reminder_time.dart';
import 'package:ippo/domain/models/scheduling_state.dart';
import 'package:ippo/domain/use_cases/save_goal.dart';
import 'package:ippo/ui/goal/goal_view_model.dart';
import 'package:ippo/ui/kana_grid/kana_detail_view_model.dart';
import 'package:ippo/ui/kana_grid/kana_grid_ui_state.dart';
import 'package:ippo/ui/kana_grid/kana_grid_view_model.dart';
import 'package:ippo/ui/settings/settings_view_model.dart';

import '../support/builders.dart';
import '../support/fake_dependencies.dart';
import '../support/seed_items.dart';

void main() {
  final now = DateTime(2026, 1, 10, 9);

  group('KanaGridViewModel', () {
    Future<KanaGridViewModel> create(FakeDependencies deps) async {
      final viewModel = KanaGridViewModel(deps.app);
      addTearDown(viewModel.dispose);
      await pumpEventQueue();
      return viewModel;
    }

    test('on a fresh install every kana is not started', () async {
      final viewModel = await create(
        FakeDependencies(items: kanaItems(hiraganaCount: 12, katakanaCount: 6)),
      );

      final state = viewModel.uiState;
      expect(state.script, KanaScript.hiragana);
      expect(state.totalCount, 12);
      expect(state.knownCount, 0);
      expect(state.learningCount, 0);
    });

    test('lays kana out in rows of five by vowel', () async {
      final viewModel =
          await create(FakeDependencies(items: kanaItems(hiraganaCount: 12)));

      expect(viewModel.uiState.sections, hasLength(1));
      expect(viewModel.uiState.sections.single.group, KanaGroup.basic);
      final rows = viewModel.uiState.sections.single.rows;
      expect(rows, hasLength(3));
      expect(
        rows[0].map((c) => c?.item.kana.character),
        ['あ', 'い', 'う', 'え', 'お'],
      );
      expect(
        rows[2].map((c) => c?.item.kana.character),
        ['さ', 'し', null, null, null],
      );
    });

    test('leaves gaps where a sound does not exist', () async {
      final viewModel = await create(
        FakeDependencies(
          items: [
            kanaItem(id: 1, character: 'や', romaji: 'ya', sortOrder: 35),
            kanaItem(id: 2, character: 'ゆ', romaji: 'yu', sortOrder: 36),
            kanaItem(id: 3, character: 'よ', romaji: 'yo', sortOrder: 37),
            kanaItem(id: 4, character: 'ん', romaji: 'n', sortOrder: 45),
          ],
        ),
      );

      final rows = viewModel.uiState.sections.single.rows;
      expect(
        rows[0].map((c) => c?.item.kana.character),
        ['や', null, 'ゆ', null, 'よ'],
      );
      expect(
        rows[1].map((c) => c?.item.kana.character),
        ['ん', null, null, null, null],
      );
    });

    test('shows learning and known kana after study', () async {
      final viewModel = await create(
        FakeDependencies(
          items: kanaItems(hiraganaCount: 12, introduced: 5),
          cards: [
            reviewCard(
              id: 1,
              itemId: 1,
              phase: CardPhase.review,
              stability: 30,
            ),
            reviewCard(id: 2, itemId: 2),
          ],
        ),
      );

      final state = viewModel.uiState;
      expect(state.knownCount, 1);
      expect(state.learningCount, 4);
      final rows = state.sections.single.rows;
      expect(rows[0][0]!.status, KanaStatus.known);
      expect(rows[0][1]!.status, KanaStatus.learning);
      expect(rows[1][0]!.status, KanaStatus.notStarted);
    });

    test('switches script', () async {
      final viewModel = await create(
        FakeDependencies(items: kanaItems(hiraganaCount: 12, katakanaCount: 6)),
      );

      viewModel.selectScript(KanaScript.katakana);

      expect(viewModel.uiState.script, KanaScript.katakana);
      expect(viewModel.uiState.totalCount, 6);
      expect(
        viewModel.uiState.sections.single.rows[0][0]!.item.kana.character,
        'ア',
      );
    });

    test('shows the real kana in three sections per script', () async {
      final viewModel =
          await create(FakeDependencies(items: seedKanaItems()));

      final state = viewModel.uiState;
      expect(state.totalCount, 104);
      expect(state.sections.map((s) => s.group), KanaGroup.values);
      int cells(KanaSection section) => section.rows
          .expand((row) => row)
          .where((cell) => cell != null)
          .length;
      expect(state.sections.map(cells), [46, 25, 33]);
      // Basic: eleven lines, a to n. Voiced: five. Combination: eleven.
      expect(state.sections.map((s) => s.rows.length), [11, 5, 11]);
      List<String?> row(int section, int index) => [
            for (final cell in state.sections[section].rows[index])
              cell?.item.kana.character,
          ];
      expect(row(0, 7), ['や', null, 'ゆ', null, 'よ']);
      expect(row(0, 9), ['わ', null, null, null, 'を']);
      expect(row(0, 10), ['ん', null, null, null, null]);
      expect(row(1, 2), ['だ', 'ぢ', 'づ', 'で', 'ど']);
      expect(row(2, 0), ['きゃ', null, 'きゅ', null, 'きょ']);

      viewModel.selectScript(KanaScript.katakana);
      expect(viewModel.uiState.totalCount, 104);
      expect(viewModel.uiState.sections.map(cells), [46, 25, 33]);
    });
  });

  group('KanaDetailViewModel', () {
    Future<KanaDetailViewModel> create(FakeDependencies deps) async {
      final viewModel = KanaDetailViewModel(deps.app, itemId: 1);
      addTearDown(viewModel.dispose);
      await pumpEventQueue();
      return viewModel;
    }

    test('shows the kana, its status and its mnemonic', () async {
      final viewModel = await create(
        FakeDependencies(items: kanaItems(hiraganaCount: 12, introduced: 1)),
      );

      final state = viewModel.uiState;
      expect(state.isLoading, isFalse);
      expect(state.item!.kana.character, 'あ');
      expect(state.status, KanaStatus.learning);
      expect(state.mnemonic!.isEdited, isFalse);
    });

    test('plays the sound of the kana', () async {
      final deps = FakeDependencies(items: kanaItems(hiraganaCount: 12));
      final viewModel = await create(deps);

      viewModel.playSound();

      expect(deps.speech.spoken, ['あ']);
    });

    test('saves the learner\'s own mnemonic', () async {
      final viewModel =
          await create(FakeDependencies(items: kanaItems(hiraganaCount: 12)));

      final saved = await viewModel.saveMnemonic('An antenna');
      await pumpEventQueue();

      expect(saved, isTrue);
      expect(viewModel.uiState.mnemonic!.text, 'An antenna');
      expect(viewModel.uiState.mnemonic!.isEdited, isTrue);
      expect(viewModel.uiState.isMnemonicInvalid, isFalse);
    });

    test('rejects an empty mnemonic and keeps the old one', () async {
      final viewModel =
          await create(FakeDependencies(items: kanaItems(hiraganaCount: 12)));
      final before = viewModel.uiState.mnemonic!.text;

      final saved = await viewModel.saveMnemonic('   ');
      await pumpEventQueue();

      expect(saved, isFalse);
      expect(viewModel.uiState.isMnemonicInvalid, isTrue);
      expect(viewModel.uiState.mnemonic!.text, before);
    });

    test('restores the default mnemonic', () async {
      final viewModel =
          await create(FakeDependencies(items: kanaItems(hiraganaCount: 12)));
      final original = viewModel.uiState.mnemonic!.text;
      await viewModel.saveMnemonic('Mine');
      await pumpEventQueue();

      await viewModel.restoreDefaultMnemonic();
      await pumpEventQueue();

      expect(viewModel.uiState.mnemonic!.text, original);
      expect(viewModel.uiState.mnemonic!.isEdited, isFalse);
    });
  });

  group('GoalViewModel', () {
    Future<GoalViewModel> create(FakeDependencies deps) async {
      final viewModel = GoalViewModel(deps.app);
      addTearDown(viewModel.dispose);
      await pumpEventQueue();
      return viewModel;
    }

    test('offers the preset when there is no goal', () async {
      final viewModel = await create(
        FakeDependencies(items: kanaItems(hiraganaCount: 46), now: now),
      );

      final state = viewModel.uiState;
      expect(state.goal, isNull);
      expect(state.startsNewGoal, isTrue);
      expect(state.targetSet, GoalTargetSet.hiragana);
      expect(state.accuracyPercent, 90);
      expect(state.deadlineDays, 14);
    });

    test('counts the kana of every target set', () async {
      final viewModel =
          await create(FakeDependencies(items: seedKanaItems(), now: now));

      expect(viewModel.uiState.targetCounts, {
        GoalTargetSet.hiragana: 46,
        GoalTargetSet.katakana: 46,
        GoalTargetSet.both: 92,
        GoalTargetSet.hiraganaExtended: 58,
        GoalTargetSet.katakanaExtended: 58,
        GoalTargetSet.everything: 208,
      });
    });

    test('keeps the counts while the form is edited', () async {
      final viewModel =
          await create(FakeDependencies(items: seedKanaItems(), now: now));

      viewModel.setTargetSet(GoalTargetSet.everything);

      expect(viewModel.uiState.targetSet, GoalTargetSet.everything);
      expect(viewModel.uiState.targetCounts[GoalTargetSet.everything], 208);
    });

    test('suggests each next step of the path after an achieved goal',
        () async {
      Future<GoalTargetSet> suggestedAfter(GoalTargetSet achieved) async {
        final viewModel = await create(
          FakeDependencies(
            items: seedKanaItems(
              introduced: achieved.includes,
              introducedAt: DateTime(2026, 1, 2),
            ),
            goal: goal(
              createdAt: DateTime(2026, 1, 1),
              targetSet: achieved,
              status: GoalStatus.achieved,
            ),
            now: now,
          ),
        );
        expect(viewModel.uiState.startsNewGoal, isTrue);
        return viewModel.uiState.targetSet;
      }

      expect(
        await suggestedAfter(GoalTargetSet.hiragana),
        GoalTargetSet.hiraganaExtended,
      );
      expect(
        await suggestedAfter(GoalTargetSet.hiraganaExtended),
        GoalTargetSet.katakana,
      );
      expect(
        await suggestedAfter(GoalTargetSet.katakana),
        GoalTargetSet.katakanaExtended,
      );
      expect(
        await suggestedAfter(GoalTargetSet.both),
        GoalTargetSet.everything,
      );
      // At the end of a path the choice stays where it was.
      expect(
        await suggestedAfter(GoalTargetSet.katakanaExtended),
        GoalTargetSet.katakanaExtended,
      );
    });

    test('saving an adjusted form creates the goal', () async {
      final deps =
          FakeDependencies(items: kanaItems(hiraganaCount: 46), now: now);
      final viewModel = await create(deps);

      viewModel.setDeadlineDays(21);
      viewModel.setAccuracyPercent(80);
      await viewModel.save();

      expect(viewModel.uiState.isSaved, isTrue);
      final saved = (await deps.goals.getCurrentGoal())!;
      expect(saved.deadline, DateTime(2026, 1, 31));
      expect(saved.targetAccuracy, 0.8);
    });

    test('an invalid deadline shows an error and saves nothing', () async {
      final deps =
          FakeDependencies(items: kanaItems(hiraganaCount: 46), now: now);
      final viewModel = await create(deps);

      viewModel.setDeadlineDays(0);
      await viewModel.save();

      expect(viewModel.uiState.error, GoalValidationError.deadlineTooShort);
      expect(viewModel.uiState.isSaved, isFalse);
      expect(await deps.goals.getCurrentGoal(), isNull);

      viewModel.setDeadlineDays(7);
      expect(viewModel.uiState.error, isNull);
    });

    test('loads an active goal for editing, with its progress', () async {
      final deps = FakeDependencies(
        items: kanaItems(hiraganaCount: 46, introduced: 10),
        goal: goal(createdAt: DateTime(2026, 1, 5), targetAccuracy: 0.8),
        now: now,
      );
      final viewModel = await create(deps);

      final state = viewModel.uiState;
      expect(state.startsNewGoal, isFalse);
      expect(state.accuracyPercent, 80);
      expect(state.deadlineDays, 14);
      expect(state.progress!.introducedCount, 10);
      expect(state.progress!.daysRemaining, 9);

      viewModel.setDeadlineDays(20);
      await viewModel.save();

      final edited = (await deps.goals.getCurrentGoal())!;
      expect(edited.id, 1);
      expect(edited.deadline, DateTime(2026, 1, 25));
    });

    test('extending a missed goal makes it active again', () async {
      final deps = FakeDependencies(
        items: kanaItems(hiraganaCount: 46, introduced: 10),
        goal: goal(createdAt: DateTime(2025, 12, 20), status: GoalStatus.missed),
        now: now,
      );
      final viewModel = await create(deps);
      expect(viewModel.uiState.startsNewGoal, isFalse);

      viewModel.setDeadlineDays(30);
      await viewModel.save();

      final extended = (await deps.goals.getCurrentGoal())!;
      expect(extended.id, 1);
      expect(extended.status, GoalStatus.active);
      expect(extended.deadline, DateTime(2026, 1, 19));
    });

    test('after an achieved goal, saving starts a new one', () async {
      final deps = FakeDependencies(
        items: kanaItems(hiraganaCount: 5, katakanaCount: 6, introduced: 5),
        goal: goal(createdAt: DateTime(2026, 1, 1), status: GoalStatus.achieved),
        now: now,
      );
      final viewModel = await create(deps);

      expect(viewModel.uiState.startsNewGoal, isTrue);
      expect(viewModel.uiState.targetSet, GoalTargetSet.hiraganaExtended);

      viewModel.setTargetSet(GoalTargetSet.katakana);
      await viewModel.save();

      final next = (await deps.goals.getCurrentGoal())!;
      expect(next.id, 2);
      expect(next.targetSet, GoalTargetSet.katakana);
      expect(next.status, GoalStatus.active);
    });
  });

  group('SettingsViewModel', () {
    Future<SettingsViewModel> create(FakeDependencies deps) async {
      final viewModel = SettingsViewModel(deps.app);
      addTearDown(viewModel.dispose);
      await pumpEventQueue();
      return viewModel;
    }

    test('loads the defaults', () async {
      final viewModel = await create(FakeDependencies());

      final state = viewModel.uiState;
      expect(state.isLoading, isFalse);
      expect(state.dailyReviewCap, 100);
      expect(state.isReminderOn, isFalse);
      expect(state.isJapaneseVoiceAvailable, isTrue);
    });

    test('changes the daily review cap', () async {
      final deps = FakeDependencies();
      final viewModel = await create(deps);

      await viewModel.setDailyReviewCap(60);

      expect(viewModel.uiState.dailyReviewCap, 60);
      expect(deps.settings.dailyReviewCap, 60);
    });

    test('turns the reminder on when permission is granted', () async {
      final deps = FakeDependencies();
      final viewModel = await create(deps);
      const time = ReminderTime(hour: 19, minute: 0);

      await viewModel.enableReminder(time);

      expect(viewModel.uiState.reminderTime, time);
      expect(viewModel.uiState.isReminderPermissionDenied, isFalse);
      expect(deps.reminders.scheduled, time);
    });

    test('keeps the reminder off when permission is refused', () async {
      final deps = FakeDependencies(notificationPermissionGranted: false);
      final viewModel = await create(deps);

      await viewModel.enableReminder(const ReminderTime(hour: 19, minute: 0));

      expect(viewModel.uiState.isReminderOn, isFalse);
      expect(viewModel.uiState.isReminderPermissionDenied, isTrue);
      expect(deps.reminders.scheduled, isNull);
      expect(deps.settings.reminderTime, isNull);
    });

    test('turns the reminder off', () async {
      final deps = FakeDependencies();
      final viewModel = await create(deps);
      await viewModel.enableReminder(const ReminderTime(hour: 7, minute: 30));

      await viewModel.disableReminder();

      expect(viewModel.uiState.isReminderOn, isFalse);
      expect(deps.reminders.scheduled, isNull);
    });

    test('reports a missing Japanese voice', () async {
      final viewModel =
          await create(FakeDependencies(japaneseVoiceAvailable: false));

      expect(viewModel.uiState.isJapaneseVoiceAvailable, isFalse);
    });
  });
}
