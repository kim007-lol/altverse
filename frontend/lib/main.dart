import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'core/services/auth_provider.dart';
import 'features/gamification/providers/mission_provider.dart';
import 'features/shared/providers/notification_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MissionProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return MaterialApp.router(
          title: 'AU Reader',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.buildLightTheme(auth.primaryColor),
          darkTheme: AppTheme.buildDarkTheme(auth.primaryColor),
          themeMode: auth.themeMode,
          routerConfig: AppRouter.router,
        );
      },
    );
  }
}
