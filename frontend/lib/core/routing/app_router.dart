import 'package:go_router/go_router.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/role_choice_screen.dart';
import '../../features/auth/screens/author_onboarding_screen.dart';
import '../../features/reader/screens/reading_screen.dart';
import '../../features/shared/screens/notification_screen.dart';
import '../../shared/widgets/master_screen.dart';

class AppRouter {
  AppRouter._();

  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/role-choice',
        builder: (context, state) => const RoleChoiceScreen(),
      ),
      GoRoute(
        path: '/author-onboarding',
        builder: (context, state) => const AuthorOnboardingScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const MasterScreen(role: 'reader'),
      ),
      GoRoute(
        path: '/author-home',
        builder: (context, state) => const MasterScreen(role: 'author'),
      ),
      GoRoute(
        path: '/reading/:seriesId/:episodeId',
        builder: (context, state) {
          final sId =
              int.tryParse(state.pathParameters['seriesId'] ?? '0') ?? 0;
          final eId =
              int.tryParse(state.pathParameters['episodeId'] ?? '0') ?? 0;
          return ReadingScreen(seriesId: sId, episodeId: eId);
        },
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationScreen(),
      ),
    ],
  );
}
