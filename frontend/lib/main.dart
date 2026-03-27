import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MoraAiApp());
}

class MoraAiApp extends StatelessWidget {
  const MoraAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Mora AI Companion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.mechaTheme,
      routerConfig: AppRouter.router,
    );
  }
}