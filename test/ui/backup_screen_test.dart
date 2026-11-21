import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ippo/domain/backup_codec.dart';
import 'package:ippo/domain/models/appearance_mode.dart';
import 'package:ippo/main.dart';

import '../support/backup_builders.dart';
import '../support/builders.dart';
import '../support/fake_dependencies.dart';

void main() {
  const codec = BackupCodec();

  Future<FakeDependencies> openBackupScreen(
    WidgetTester tester, {
    AppearanceMode mode = AppearanceMode.automatic,
  }) async {
    final deps = FakeDependencies(items: kanaItems(hiraganaCount: 12));
    deps.settings.appearanceMode = mode;
    await tester.pumpWidget(
      IppoApp(dependencies: deps.app, initialAppearanceMode: mode),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Backup and restore'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Backup and restore'));
    await tester.pumpAndSettle();
    return deps;
  }

  /// Scrolls the top screen until [target] is built and fully on screen.
  Future<void> bringIntoView(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(
      target,
      120,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
  }

  testWidgets('settings opens the Backup screen', (tester) async {
    await openBackupScreen(tester);

    expect(find.text('Export backup'), findsOneWidget);
    expect(find.text('Import backup'), findsOneWidget);
    expect(find.text('No export made yet.'), findsOneWidget);
    expect(find.textContaining('backs up Ippo automatically'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Daily review limit'), findsOneWidget);
  });

  testWidgets('an export is confirmed and dated', (tester) async {
    final deps = await openBackupScreen(tester);

    await tester.tap(find.text('Export backup'));
    await tester.pumpAndSettle();

    expect(deps.backupFiles.saved, hasLength(1));
    expect(find.text('Backup saved'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    expect(find.textContaining('Last export:'), findsOneWidget);
    expect(find.text('No export made yet.'), findsNothing);
  });

  testWidgets('an import shows a summary, then replaces on confirmation', (
    tester,
  ) async {
    final deps = await openBackupScreen(tester);
    deps.backupFiles.fileToPick = codec.encode(fullSnapshot());

    await tester.tap(find.text('Import backup'));
    await tester.pumpAndSettle();

    expect(find.text('Replace your data?'), findsOneWidget);
    expect(find.text('In the file'), findsOneWidget);
    expect(find.text('On this phone'), findsOneWidget);
    expect(find.text('Kana learned'), findsOneWidget);
    expect(deps.backups.replaced, isEmpty);

    await tester.scrollUntilVisible(
      find.text('Replace data on this phone'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Replace data on this phone'));
    await tester.pumpAndSettle();

    expect(deps.backups.replaced, hasLength(1));
    expect(find.text('Data restored'), findsOneWidget);
  });

  testWidgets('cancelling at the summary changes nothing', (tester) async {
    final deps = await openBackupScreen(tester);
    deps.backupFiles.fileToPick = codec.encode(fullSnapshot());
    await tester.tap(find.text('Import backup'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Cancel'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(deps.backups.replaced, isEmpty);
    expect(find.text('Export backup'), findsOneWidget);
    expect(find.text('Data restored'), findsNothing);
  });

  testWidgets('a file that is not a backup is refused in plain words', (
    tester,
  ) async {
    final deps = await openBackupScreen(tester);
    deps.backupFiles.fileToPick = 'holiday notes';

    await tester.tap(find.text('Import backup'));
    await tester.pumpAndSettle();

    expect(find.text('Not an Ippo backup'), findsOneWidget);
    expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
    expect(find.textContaining('Nothing was changed'), findsOneWidget);
    expect(deps.backups.replaced, isEmpty);

    await tester.tap(find.text('Dismiss'));
    await tester.pumpAndSettle();
    expect(find.text('Not an Ippo backup'), findsNothing);
  });

  for (final mode in [
    AppearanceMode.daylight,
    AppearanceMode.night,
    AppearanceMode.paper,
  ]) {
    testWidgets('fits a small screen with large text in ${mode.name}', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      // Any overflow raises an error, which fails the test.
      final deps = await openBackupScreen(tester, mode: mode);
      final list = find.byType(Scrollable).last;
      await tester.drag(list, const Offset(0, -900));
      await tester.pumpAndSettle();
      await tester.drag(list, const Offset(0, 900));
      await tester.pumpAndSettle();

      // A refusal notice.
      deps.backupFiles.fileToPick = 'holiday notes';
      await bringIntoView(tester, find.text('Import backup'));
      await tester.tap(find.text('Import backup'));
      await tester.pumpAndSettle();
      expect(find.text('Not an Ippo backup'), findsOneWidget);

      // The confirm step.
      deps.backupFiles.fileToPick = codec.encode(fullSnapshot());
      await bringIntoView(tester, find.text('Import backup'));
      await tester.tap(find.text('Import backup'));
      await tester.pumpAndSettle();
      expect(find.text('Replace your data?'), findsOneWidget);
      await tester.drag(find.byType(Scrollable).last, const Offset(0, -900));
      await tester.pumpAndSettle();
      expect(find.text('Replace data on this phone'), findsOneWidget);
    });
  }
}
