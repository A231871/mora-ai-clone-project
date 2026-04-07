import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/app_settings_service.dart';
import 'core/services/notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'core/providers/language_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettingsService.instance.ensureInitialized();
  await NotificationService().init();
  if (await NotificationService().isEnabled()) {
    await NotificationService().requestPermissions();
  }
  runApp(const ProviderScope(child: ShizukiApp()));
}

class ShizukiApp extends ConsumerWidget {
  const ShizukiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(languageProvider);

    return MaterialApp.router(
      title: 'Shizuki AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.mechaTheme,
      routerConfig: AppRouter.router,
      locale: currentLocale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('vi'),
      ],
    );
  }
}
