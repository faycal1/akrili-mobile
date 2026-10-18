import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/config/app_config.dart';
import 'core/localization/app_localizations.dart';
import 'core/notifications/fcm_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/locale_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize FCM service with deep link navigation
  await FcmService.instance.initialize(
    onDeepLinkAction: (String type, String id) {
      final context = rootNavigatorKey.currentContext;
      if (context != null) {
        if (type == 'booking') {
          GoRouter.of(context).push('/bookings/$id');
        } else if (type == 'conversation') {
          GoRouter.of(context).push('/conversations/$id');
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
    final locale = ref.watch(appLocaleProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}

