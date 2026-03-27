import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/screens/start_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/reminders/screens/reminders_screen.dart';
import '../../features/config/screens/config_screen.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'start',
        pageBuilder: (_, state) => _fade(state, const StartScreen()),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (_, state) => _fade(state, const LoginScreen()),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        pageBuilder: (_, state) => _fade(state, const SignupScreen()),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        pageBuilder: (_, state) => _fade(state, const HomeScreen()),
      ),
      GoRoute(
        path: '/chat',
        name: 'chat',
        pageBuilder: (_, state) => _fade(state, const ChatScreen()),
      ),
      GoRoute(
        path: '/reminders',
        name: 'reminders',
        pageBuilder: (_, state) => _fade(state, const RemindersScreen()),
      ),
      GoRoute(
        path: '/config',
        name: 'config',
        pageBuilder: (_, state) => _fade(state, const ConfigScreen()),
      ),
    ],
  );

  /// Smooth fade-in transition for all routes.
  static CustomTransitionPage<void> _fade(
    GoRouterState state,
    Widget child,
  ) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 350),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    );
  }
}
