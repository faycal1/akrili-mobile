import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/app_config.dart';
import 'core/notifications/fcm_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize FCM service with deep link navigation
  await FcmService.instance.initialize(
    onDeepLinkAction: (String type, String id) {
      final context = rootNavigatorKey.currentContext;
      if (context != null) {
        if (type == 'booking') {
          rootNavigatorKey.currentState?.pushNamed('/bookings/$id');
        } else if (type == 'conversation') {
          rootNavigatorKey.currentState?.pushNamed('/conversations/$id');
        }
      }
    },
  );

  runApp(
    const ProviderScope(
      child: AkriliApp(),
    ),
  );
}

class AkriliApp extends ConsumerWidget {
  const AkriliApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
