import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:ippo/app_dependencies.dart';
import 'package:ippo/data/repositories/drift_card_repository.dart';
import 'package:ippo/data/repositories/drift_goal_repository.dart';
import 'package:ippo/data/repositories/drift_item_repository.dart';
import 'package:ippo/data/repositories/drift_mnemonic_repository.dart';
import 'package:ippo/data/repositories/drift_review_repository.dart';
import 'package:ippo/data/repositories/drift_settings_repository.dart';
import 'package:ippo/data/repositories/drift_unit_of_work.dart';
import 'package:ippo/data/repositories/local_notification_reminder_repository.dart';
import 'package:ippo/data/repositories/tts_speech_repository.dart';
import 'package:ippo/data/seed/kana_seed_loader.dart';
import 'package:ippo/data/services/app_database.dart';
import 'package:ippo/data/services/notification_service.dart';
import 'package:ippo/data/services/tts_service.dart';
import 'package:ippo/domain/scheduling/fsrs_scheduler.dart';
import 'package:ippo/routing/app_router.dart';
import 'package:ippo/ui/core/app_theme.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = AppDatabase(driftDatabase(name: 'ippo'));
  final itemRepository = DriftItemRepository(database);
  final dependencies = AppDependencies(
    itemRepository: itemRepository,
    mnemonicRepository: DriftMnemonicRepository(database),
    cardRepository: DriftCardRepository(database),
    reviewRepository: DriftReviewRepository(database),
    goalRepository: DriftGoalRepository(database),
    settingsRepository: DriftSettingsRepository(database),
    speechRepository: TtsSpeechRepository(TtsService()),
    reminderRepository:
        LocalNotificationReminderRepository(NotificationService()),
    unitOfWork: DriftUnitOfWork(database),
    scheduler: FsrsScheduler(),
  );

  await KanaSeedLoader(
    itemRepository: itemRepository,
    loadSeedJson: () => rootBundle.loadString(KanaSeedLoader.assetPath),
  ).seed();

  runApp(IppoApp(dependencies: dependencies));
}

class IppoApp extends StatefulWidget {
  const IppoApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<IppoApp> createState() => _IppoAppState();
}

class _IppoAppState extends State<IppoApp> {
  late final GoRouter _router = createAppRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Provider<AppDependencies>.value(
      value: widget.dependencies,
      child: MaterialApp.router(
        title: 'Ippo',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        routerConfig: _router,
      ),
    );
  }
}
