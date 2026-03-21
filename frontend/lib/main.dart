import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MoraAiApp());
}

class MoraAiApp extends StatelessWidget {
  const MoraAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mora AI Companion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.mechaTheme,
      home: const LoginScreen(), // We will add an AuthChecker here later to skip login if token exists
    );
  }
}