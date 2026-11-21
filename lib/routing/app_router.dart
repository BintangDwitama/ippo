import 'package:go_router/go_router.dart';
import 'package:ippo/app_dependencies.dart';
import 'package:ippo/routing/routes.dart';
import 'package:ippo/ui/backup/backup_screen.dart';
import 'package:ippo/ui/backup/backup_view_model.dart';
import 'package:ippo/ui/goal/goal_screen.dart';
import 'package:ippo/ui/goal/goal_view_model.dart';
import 'package:ippo/ui/home/home_screen.dart';
import 'package:ippo/ui/home/home_view_model.dart';
import 'package:ippo/ui/kana_grid/kana_detail_screen.dart';
import 'package:ippo/ui/kana_grid/kana_detail_view_model.dart';
import 'package:ippo/ui/kana_grid/kana_grid_screen.dart';
import 'package:ippo/ui/kana_grid/kana_grid_view_model.dart';
import 'package:ippo/ui/lesson/lesson_screen.dart';
import 'package:ippo/ui/lesson/lesson_view_model.dart';
import 'package:ippo/ui/review/review_screen.dart';
import 'package:ippo/ui/review/review_view_model.dart';
import 'package:ippo/ui/settings/settings_screen.dart';
import 'package:ippo/ui/settings/settings_view_model.dart';
import 'package:provider/provider.dart';

/// Builds the app's routes. Each route creates its screen's ViewModel,
/// which lives exactly as long as the screen.
GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: Routes.home,
    routes: [
      GoRoute(
        path: Routes.home,
        builder: (context, state) => ChangeNotifierProvider(
          create: (context) => HomeViewModel(context.read<AppDependencies>()),
          child: const HomeScreen(),
        ),
      ),
      GoRoute(
        path: Routes.lesson,
        builder: (context, state) => ChangeNotifierProvider(
          create: (context) =>
              LessonViewModel(context.read<AppDependencies>()),
          child: const LessonScreen(),
        ),
      ),
      GoRoute(
        path: Routes.review,
        builder: (context, state) => ChangeNotifierProvider(
          create: (context) =>
              ReviewViewModel(context.read<AppDependencies>()),
          child: const ReviewScreen(),
        ),
      ),
      GoRoute(
        path: Routes.kanaGrid,
        builder: (context, state) => ChangeNotifierProvider(
          create: (context) =>
              KanaGridViewModel(context.read<AppDependencies>()),
          child: const KanaGridScreen(),
        ),
        routes: [
          GoRoute(
            path: ':itemId',
            builder: (context, state) => ChangeNotifierProvider(
              create: (context) => KanaDetailViewModel(
                context.read<AppDependencies>(),
                itemId: int.parse(state.pathParameters['itemId']!),
              ),
              child: const KanaDetailScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: Routes.goal,
        builder: (context, state) => ChangeNotifierProvider(
          create: (context) => GoalViewModel(context.read<AppDependencies>()),
          child: const GoalScreen(),
        ),
      ),
      GoRoute(
        path: Routes.settings,
        builder: (context, state) => ChangeNotifierProvider(
          create: (context) =>
              SettingsViewModel(context.read<AppDependencies>()),
          child: const SettingsScreen(),
        ),
        routes: [
          GoRoute(
            path: 'backup',
            builder: (context, state) => ChangeNotifierProvider(
              create: (context) =>
                  BackupViewModel(context.read<AppDependencies>()),
              child: const BackupScreen(),
            ),
          ),
        ],
      ),
    ],
  );
}
