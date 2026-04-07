import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/services/api_client.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/workspace_models.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/mecha_panel.dart';
import '../../../shared/widgets/workspace_empty_state.dart';
import '../../../shared/widgets/workspace_screen_shell.dart';
import '../../auth/services/session_storage.dart';
import '../services/users_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final UsersService _usersService = UsersService();
  final TextEditingController _searchController = TextEditingController();

  List<AppUser> _users = const <AppUser>[];
  AppUser? _currentUser;
  bool _loading = true;
  bool _forbidden = false;
  String? _busyUserId;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    _currentUser = await SessionStorage.getCurrentUser();
    await _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _forbidden = false;
    });

    try {
      final users = await _usersService.listUsers(
        query: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _users = users;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _forbidden = error.statusCode == 403;
      });
      if (error.statusCode != 403) {
        _showMessage(error.message);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      _showMessage('Failed to load users: $error');
    }
  }

  Future<void> _updateRole(AppUser user, String role) async {
    setState(() => _busyUserId = user.id);
    try {
      await _usersService.updateUserRole(user.id, systemRole: role);
      if (!mounted) {
        return;
      }
      _showMessage('Role updated.', isError: false);
      await _loadUsers();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _busyUserId = null);
      _showMessage(error.message);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _busyUserId = null);
      _showMessage('Role update failed: $error');
    }
  }

  Future<void> _deleteUser(AppUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: Text('Delete ${user.username}?', style: AppTextStyles.titleMedium),
        content: Text(
          'This removes the account and any server-side access tied to it.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'DELETE',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() => _busyUserId = user.id);
    try {
      await _usersService.deleteUser(user.id);
      if (!mounted) {
        return;
      }
      _showMessage('User deleted.', isError: false);
      await _loadUsers();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _busyUserId = null);
      _showMessage(error.message);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _busyUserId = null);
      _showMessage('Delete failed: $error');
    }
  }

  void _handleSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), _loadUsers);
  }

  void _showMessage(String message, {bool isError = true}) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.bgCard,
        content: Text(
          message,
          style: TextStyle(
            color: isError ? Colors.redAccent : Colors.greenAccent,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WorkspaceScreenShell(
      title: 'Admin Users',
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: _handleSearchChanged,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Search username or email',
              suffixIcon: IconButton(
                onPressed: _loading ? null : _loadUsers,
                icon: const Icon(Icons.search, color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _forbidden
                    ? Center(
                        child: WorkspaceEmptyState(
                          icon: Icons.lock_outline,
                          title: 'Admin Access Required',
                          message:
                              'This screen is hidden for non-admin members. Backend access rules are active.',
                        ),
                      )
                    : _users.isEmpty
                        ? Center(
                            child: WorkspaceEmptyState(
                              icon: Icons.people_outline,
                              title: 'No Users Found',
                              message:
                                  'Try a different search term or refresh the admin roster.',
                            ),
                          )
                        : ListView.separated(
                            itemCount: _users.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: AppSpacing.md),
                            itemBuilder: (context, index) {
                              final user = _users[index];
                              final isBusy = _busyUserId == user.id;
                              final isSelf = user.id == _currentUser?.id;
                              return MechaPanel(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                user.resolvedDisplayName,
                                                style: AppTextStyles.titleMedium,
                                              ),
                                              const SizedBox(
                                                height: AppSpacing.xs,
                                              ),
                                              Text(
                                                '${user.username} · ${user.email ?? 'no email'}',
                                                style: AppTextStyles.bodySmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isSelf)
                                          Text(
                                            'YOU',
                                            style: AppTextStyles.caption
                                                .copyWith(
                                              color: AppColors.primary,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    Wrap(
                                      spacing: AppSpacing.sm,
                                      runSpacing: AppSpacing.sm,
                                      children: [
                                        _MetaPill(
                                          label: 'ROLE ${user.systemRole.toUpperCase()}',
                                        ),
                                        _MetaPill(
                                          label:
                                              'LAST LOGIN ${formatShortDate(user.lastLoginAt)}',
                                        ),
                                        _MetaPill(
                                          label:
                                              'CREATED ${formatShortDate(user.createdAt)}',
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    Row(
                                      children: [
                                        DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: user.systemRole,
                                            dropdownColor: AppColors.bgCard,
                                            style: AppTextStyles.bodyMedium,
                                            items: const [
                                              DropdownMenuItem(
                                                value: 'member',
                                                child: Text('MEMBER'),
                                              ),
                                              DropdownMenuItem(
                                                value: 'admin',
                                                child: Text('ADMIN'),
                                              ),
                                            ],
                                            onChanged: isBusy
                                                ? null
                                                : (value) {
                                                    if (value == null ||
                                                        value == user.systemRole) {
                                                      return;
                                                    }
                                                    _updateRole(user, value);
                                                  },
                                          ),
                                        ),
                                        const Spacer(),
                                        TextButton.icon(
                                          onPressed: isBusy || isSelf
                                              ? null
                                              : () => _deleteUser(user),
                                          icon: isBusy
                                              ? const SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                  ),
                                                )
                                              : const Icon(
                                                  Icons.delete_outline,
                                                  color: Colors.redAccent,
                                                ),
                                          label: Text(
                                            'DELETE',
                                            style: AppTextStyles.caption
                                                .copyWith(
                                              color: Colors.redAccent,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.16),
        ),
      ),
      child: Text(label, style: AppTextStyles.caption),
    );
  }
}
