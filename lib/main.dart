import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import 'package:ippo/app_dependencies.dart';
import 'package:ippo/data/repositories/drift_backup_repository.dart';
import 'package:ippo/data/repositories/drift_card_repository.dart';
import 'package:ippo/data/repositories/drift_goal_repository.dart';
import 'package:ippo/data/repositories/drift_item_repository.dart';
import 'package:ippo/data/repositories/drift_mnemonic_repository.dart';
import 'package:ippo/data/repositories/drift_review_repository.dart';
import 'package:ippo/data/repositories/drift_settings_repository.dart';
import 'package:ippo/data/repositories/drift_unit_of_work.dart';
import 'package:ippo/data/repositories/file_picker_backup_file_repository.dart';
import 'package:ippo/data/repositories/local_notification_reminder_repository.dart';
import 'package:ippo/data/repositories/tts_speech_repository.dart';
import 'package:ippo/data/seed/kana_seed_loader.dart';
import 'package:ippo/data/services/app_database.dart';
import 'package:ippo/data/services/notification_service.dart';
import 'package:ippo/data/services/tts_service.dart';
import 'package:ippo/domain/scheduling/fsrs_scheduler.dart';
import 'package:ippo/routing/app_router.dart';
import 'package:ippo/domain/models/appearance_mode.dart';
import 'package:ippo/ui/app/app_view_model.dart';
import 'package:ippo/ui/core/theme/app_themes.dart';
import 'package:ippo/ui/core/theme/font_licenses.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicenses(rootBundle.loadString);

  final database = AppDatabase(driftDatabase(name: 'ippo'));
  final itemRepository = DriftItemRepository(database);
  final settingsRepository = DriftSettingsRepository(database);
  final dependencies = AppDependencies(
    itemRepository: itemRepository,
    mnemonicRepository: DriftMnemonicRepository(database),
    cardRepository: DriftCardRepository(database),
    reviewRepository: DriftReviewRepository(database),
    goalRepository: DriftGoalRepository(database),
    settingsRepository: settingsRepository,
    speechRepository: TtsSpeechRepository(TtsService()),
    reminderRepository:
        LocalNotificationReminderRepository(NotificationService()),
    backupRepository: DriftBackupRepository(database, settingsRepository),
    backupFileRepository: const FilePickerBackupFileRepository(),
    unitOfWork: DriftUnitOfWork(database),
    scheduler: FsrsScheduler(),
  );

  await KanaSeedLoader(
    itemRepository: itemRepository,
    loadSeedJson: () => rootBundle.loadString(KanaSeedLoader.assetPath),
  ).seed();

  // Read before the first frame so the app never flashes another theme.
  final appearanceMode = await settingsRepository.getAppearanceMode();

  runApp(
    IppoApp(
      dependencies: dependencies,
      initialAppearanceMode: appearanceMode,
    ),
  );

  // The phone may have restored the app's data without the app knowing,
  // which brings back the reminder setting but not its schedule. A
  // failure here must not stop the app; the reminder is a convenience.
  unawaited(dependencies.reconcileReminder().catchError((Object _) {}));
}

class IppoApp extends StatefulWidget {
  const IppoApp({
    super.key,
    required this.dependencies,
    this.initialAppearanceMode = AppearanceMode.automatic,
  });

  final AppDependencies dependencies;

  /// The stored appearance, shown from the first frame.
  final AppearanceMode initialAppearanceMode;

  @override
  State<IppoApp> createState() => _IppoAppState();
}

class _IppoAppState extends State<IppoApp> {
  late final GoRouter _router = createAppRouter();
  late final AppViewModel _viewModel = AppViewModel(
    widget.dependencies.settingsRepository,
    initialAppearanceMode: widget.initialAppearanceMode,
  );

  @override
  void dispose() {
    _viewModel.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Provider<AppDependencies>.value(
      value: widget.dependencies,
      child: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final selection =
              AppThemes.forMode(_viewModel.uiState.appearanceMode);
          return MaterialApp.router(
            title: 'Ippo',
            debugShowCheckedModeBanner: false,
            theme: selection.theme,
            darkTheme: selection.darkTheme,
            themeMode: selection.themeMode,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
