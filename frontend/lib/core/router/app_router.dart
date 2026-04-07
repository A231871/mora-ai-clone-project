import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/services/session_storage.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/config/screens/config_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/reminders/screens/reminders_screen.dart';
import '../../features/splash/screens/start_screen.dart';
import '../../features/workspace/screens/admin_console_screen.dart';
import '../../features/workspace/screens/files_vault_screen.dart';
import '../../features/workspace/screens/profile_screen.dart';
import '../../features/workspace/screens/project_workspace_screen.dart';
import '../../features/workspace/screens/projects_list_screen.dart';
import '../../features/workspace/screens/task_detail_screen.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    redirect: (_, state) async {
      final loggedIn = await SessionStorage.isLoggedIn();
      final location = state.matchedLocation;
      const publicRoutes = <String>{'/', '/login', '/signup'};
      final isPublicRoute = publicRoutes.contains(location);

      if (!loggedIn && !isPublicRoute) {
        return '/login';
      }

      if (loggedIn && isPublicRoute) {
        return '/home';
      }

      return null;
    },
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
      GoRoute(
        path: '/projects',
        name: 'projects',
        pageBuilder: (_, state) => _fade(state, const ProjectsListScreen()),
        routes: [
          GoRoute(
            path: ':projectId',
            name: 'project-workspace',
            pageBuilder: (_, state) => _fade(
              state,
              ProjectWorkspaceScreen(
                projectId: state.pathParameters['projectId']!,
              ),
            ),
            routes: [
              GoRoute(
                path: 'tasks/:taskId',
                name: 'task-detail',
                pageBuilder: (_, state) => _fade(
                  state,
                  TaskDetailScreen(
                    projectId: state.pathParameters['projectId']!,
                    taskId: state.pathParameters['taskId']!,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/files',
        name: 'files',
        pageBuilder: (_, state) => _fade(state, const FilesVaultScreen()),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        pageBuilder: (_, state) => _fade(state, const ProfileScreen()),
      ),
      GoRoute(
        path: '/admin',
        name: 'admin-console',
        pageBuilder: (_, state) => _fade(state, const AdminConsoleScreen()),
      ),
      GoRoute(
        path: '/admin/users',
        redirect: (_, __) => '/admin',
      ),
    ],
  );

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
