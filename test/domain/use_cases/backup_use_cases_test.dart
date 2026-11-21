import 'package:flutter_test/flutter_test.dart';
import 'package:ippo/domain/backup_codec.dart';
import 'package:ippo/domain/models/reminder_time.dart';

import '../../support/backup_builders.dart';
import '../../support/builders.dart';
import '../../support/fake_dependencies.dart';

void main() {
  const codec = BackupCodec();
  const evening = ReminderTime(hour: 19, minute: 30);
  final now = DateTime(2026, 11, 21, 9, 15);

  group('ReconcileReminder', () {
    test(
      'schedules a stored reminder when notifications are allowed',
      () async {
        final deps = FakeDependencies();
        deps.settings.reminderTime = evening;

        await deps.app.reconcileReminder();

        expect(deps.reminders.scheduled, evening);
        expect(deps.settings.reminderTime, evening);
        expect(deps.reminders.permissionRequests, 0);
      },
    );

    test(
      'turns a stored reminder off when notifications are not allowed',
      () async {
        final deps = FakeDependencies(notificationPermissionGranted: false);
        deps.settings.reminderTime = evening;

        await deps.app.reconcileReminder();

        expect(deps.reminders.scheduled, isNull);
        expect(deps.settings.reminderTime, isNull);
        expect(deps.reminders.permissionRequests, 0);
      },
    );

    test('cancels a leftover schedule when no reminder is stored', () async {
      final deps = FakeDependencies();
      deps.reminders.scheduled = evening;

      await deps.app.reconcileReminder();

      expect(deps.reminders.scheduled, isNull);
      expect(deps.settings.reminderTime, isNull);
    });
  });

  group('ExportBackup', () {
    test('names the file by the local date and encodes the data', () async {
      final deps = FakeDependencies();
      deps.backups.current = fullSnapshot();

      final export = await deps.app.exportBackup(now: now);

      expect(export.fileName, 'ippo-backup-2026-11-21.json');
      final decoded = codec.decode(export.text);
      expect(decoded.exportedAt, now.toUtc());
      expect(decoded.cards, hasLength(3));
      expect(decoded.settings.dailyReviewCap, 60);
      expect(deps.backups.replaced, isEmpty);
    });
  });

  group('ReadBackup', () {
    FakeDependencies withKana() =>
        FakeDependencies(items: kanaItems(hiraganaCount: 12));

    test('summarises the file next to what is on the phone', () async {
      final deps = withKana();

      final preview = await deps.app.readBackup(
        text: codec.encode(fullSnapshot()),
        now: now,
      );

      expect(preview.inFile.exportedAt, DateTime.utc(2026, 11, 21, 2, 15));
      expect(preview.inFile.introducedCount, 2);
      expect(preview.inFile.cardCount, 3);
      expect(preview.inFile.reviewCount, 2);
      expect(preview.onPhone.introducedCount, 0);
      expect(preview.onPhone.cardCount, 0);
      expect(preview.snapshot.cards, hasLength(3));
      // Reading changes nothing.
      expect(deps.backups.replaced, isEmpty);
    });

    test('refuses a file that is not a backup', () async {
      final deps = withKana();

      await expectLater(
        deps.app.readBackup(text: 'shopping list', now: now),
        throwsA(
          isA<BackupFormatException>().having(
            (e) => e.problem,
            'problem',
            BackupFormatProblem.notABackup,
          ),
        ),
      );
    });

    test('refuses a backup naming kana this app does not have', () async {
      final deps = withKana();
      final text = codec.encode(
        fullSnapshot(keys: ['hiragana:a', 'hiragana:kya']),
      );

      await expectLater(
        deps.app.readBackup(text: text, now: now),
        throwsA(
          isA<BackupFormatException>()
              .having(
                (e) => e.problem,
                'problem',
                BackupFormatProblem.unknownItems,
              )
              .having((e) => e.detail, 'detail', 'hiragana:kya'),
        ),
      );
    });
  });

  group('RestoreBackup', () {
    test(
      'replaces the data and then schedules the restored reminder',
      () async {
        final deps = FakeDependencies();
        final snapshot = fullSnapshot();
        // The fake backup repository does not write settings, so stand in
        // for what the real one stores from the snapshot.
        deps.settings.reminderTime = snapshot.settings.reminderTime;

        await deps.app.restoreBackup(snapshot);

        expect(deps.backups.replaced.single, same(snapshot));
        expect(deps.reminders.scheduled, evening);
        expect(deps.reminders.permissionRequests, 0);
      },
    );

    test(
      'shows the reminder as off when this phone blocks notifications',
      () async {
        final deps = FakeDependencies(notificationPermissionGranted: false);
        deps.settings.reminderTime = evening;

        await deps.app.restoreBackup(fullSnapshot());

        expect(deps.reminders.scheduled, isNull);
        expect(deps.settings.reminderTime, isNull);
        expect(deps.reminders.permissionRequests, 0);
      },
    );

    test('leaves the reminder alone when replacing fails', () async {
      final deps = FakeDependencies();
      deps.backups.failOnReplace = true;
      deps.reminders.scheduled = const ReminderTime(hour: 7, minute: 0);
      deps.settings.reminderTime = const ReminderTime(hour: 7, minute: 0);

      await expectLater(
        deps.app.restoreBackup(fullSnapshot()),
        throwsA(isA<StateError>()),
      );

      expect(deps.reminders.scheduled, const ReminderTime(hour: 7, minute: 0));
      expect(
        deps.settings.reminderTime,
        const ReminderTime(hour: 7, minute: 0),
      );
    });
  });
}
