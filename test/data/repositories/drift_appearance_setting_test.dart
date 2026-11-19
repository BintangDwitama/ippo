import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ippo/data/repositories/drift_settings_repository.dart';
import 'package:ippo/data/services/app_database.dart';
import 'package:ippo/domain/models/appearance_mode.dart';

void main() {
  late AppDatabase db;
  late DriftSettingsRepository settings;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    settings = DriftSettingsRepository(db);
  });

  tearDown(() => db.close());

  test('the appearance is automatic until the learner chooses', () async {
    expect(await settings.getAppearanceMode(), AppearanceMode.automatic);
  });

  test('stores the chosen appearance', () async {
    await settings.setAppearanceMode(AppearanceMode.paper);

    expect(await settings.getAppearanceMode(), AppearanceMode.paper);
    // A second repository on the same database sees it: it is persisted.
    expect(
      await DriftSettingsRepository(db).getAppearanceMode(),
      AppearanceMode.paper,
    );
  });

  test('treats an unrecognised stored value as automatic', () async {
    await db
        .into(db.settings)
        .insertOnConflictUpdate(
          SettingsCompanion.insert(name: 'appearance_mode', value: 'sepia'),
        );

    expect(await settings.getAppearanceMode(), AppearanceMode.automatic);
  });

  test('the stream emits the current value and then each change', () async {
    final emitted = <AppearanceMode>[];
    final subscription = settings.getAppearanceModeStream().listen(emitted.add);
    addTearDown(subscription.cancel);
    await pumpEventQueue();

    await settings.setAppearanceMode(AppearanceMode.night);
    await pumpEventQueue();
    await settings.setAppearanceMode(AppearanceMode.paper);
    await pumpEventQueue();

    expect(emitted, [
      AppearanceMode.automatic,
      AppearanceMode.night,
      AppearanceMode.paper,
    ]);
  });

  test('changing another setting does not emit an appearance change', () async {
    final emitted = <AppearanceMode>[];
    final subscription = settings.getAppearanceModeStream().listen(emitted.add);
    addTearDown(subscription.cancel);
    await pumpEventQueue();

    await settings.setDailyReviewCap(40);
    await pumpEventQueue();

    expect(emitted, [AppearanceMode.automatic]);
  });
}
