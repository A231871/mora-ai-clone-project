import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/services/api_client.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/workspace_models.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/kpi_chip.dart';
import '../../../shared/widgets/mecha_button.dart';
import '../../../shared/widgets/mecha_panel.dart';
import '../../../shared/widgets/mecha_text_field.dart';
import '../../../shared/widgets/responsive_action_group.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../../shared/widgets/workspace_screen_shell.dart';
import '../../auth/services/auth_service.dart';
import '../services/users_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UsersService _usersService = UsersService();
  final AuthService _authService = AuthService();

  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  AppUser? _user;
  List<ProjectInvite> _pendingInvites = const <ProjectInvite>[];
  bool _loading = true;
  bool _saving = false;
  bool _loggingOut = false;
  String? _busyInviteId;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait<dynamic>([
        _usersService.getCurrentUser(),
        _usersService.listMyInvites(),
      ]);
      final user = results[0] as AppUser;
      final invites = results[1] as List<ProjectInvite>;

      if (!mounted) {
        return;
      }

      _displayNameController.text = user.displayName ?? '';
      _emailController.text = user.email ?? '';
      _bioController.text = user.bio ?? '';

      setState(() {
        _user = user;
        _pendingInvites = invites.where((invite) => invite.isPending).toList();
        _busyInviteId = null;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      _showMessage(error.message);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      _showMessage('Failed to load profile: $error');
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      final updatedUser = await _usersService.updateCurrentUser(
        displayName: _displayNameController.text.trim(),
        bio: _bioController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _user = updatedUser;
        _saving = false;
      });
      _showMessage('Profile updated successfully.', isError: false);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      _showMessage(error.message);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      _showMessage('Save failed: $error');
    }
  }

  Future<void> _respondToInvite(
    ProjectInvite invite, {
    required String action,
  }) async {
    setState(() => _busyInviteId = invite.id);
    try {
      await _usersService.respondToInvite(invite.id, action: action);
      if (!mounted) {
        return;
      }
      _showMessage(
        action == 'accept' ? 'Invitation accepted.' : 'Invitation declined.',
        isError: false,
      );
      await _loadProfile();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _busyInviteId = null);
      _showMessage(error.message);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _busyInviteId = null);
      _showMessage('Invite action failed: $error');
    }
  }

  Future<void> _logout({required bool allSessions}) async {
    setState(() => _loggingOut = true);
    try {
      if (allSessions) {
        await _authService.logoutAll();
      } else {
        await _authService.logout();
      }

      if (!mounted) {
        return;
      }
      context.go('/login');
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _loggingOut = false);
      _showMessage('Logout failed: $error');
    }
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
    final user = _user;

    return WorkspaceScreenShell(
      title: 'Profile / Inbox',
      trailing: IconButton(
        onPressed: _loading ? null : _loadProfile,
        icon: const Icon(Icons.refresh, color: AppColors.primary),
      ),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                if (user != null) ...[
                  MechaPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.resolvedDisplayName,
                                    style: AppTextStyles.displayMedium
                                        .copyWith(fontSize: 24),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    '@${user.username}',
                                    style: AppTextStyles.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            StatusChip(
                              label: user.systemRole.toUpperCase(),
                              color: user.isAdmin
                                  ? AppColors.statusGreen
                                  : AppColors.primary,
                              textColor: user.isAdmin
                                  ? AppColors.statusGreen
                                  : AppColors.textPrimary,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            const KpiChip(label: 'Session', value: 'ACTIVE'),
                            KpiChip(
                              label: 'Pending Invites',
                              value: '${_pendingInvites.length}',
                            ),
                            KpiChip(
                              label: 'Last Login',
                              value: formatShortDate(user.lastLoginAt),
                            ),
                            KpiChip(
                              label: 'Created',
                              value: formatShortDate(user.createdAt),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                MechaPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Identity',
                        style: AppTextStyles.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      MechaTextField(
                        label: 'DISPLAY NAME',
                        hint: 'Commander name',
                        controller: _displayNameController,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      MechaTextField(
                        label: 'EMAIL',
                        hint: 'pilot@workspace.dev',
                        controller: _emailController,
                        readOnly: true,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      const Text(
                        'Email stays locked until account verification and provider-safe email change flows exist.',
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Text('BIO', style: AppTextStyles.caption),
                      const SizedBox(height: AppSpacing.xs),
                      TextField(
                        controller: _bioController,
                        style: AppTextStyles.bodyMedium,
                        minLines: 3,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          hintText: 'Short mission briefing for your profile',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      MechaButton(
                        label: _saving ? 'SAVING...' : 'SAVE PROFILE',
                        onTap: _saving ? null : _saveProfile,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                MechaPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pending Invitations',
                        style: AppTextStyles.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (_pendingInvites.isEmpty)
                        const Text(
                          'No pending project invitations right now.',
                          style: AppTextStyles.bodySmall,
                        )
                      else
                        Column(
                          children: _pendingInvites
                              .map(
                                (invite) => Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.md,
                                  ),
                                  child: _InviteCard(
                                    invite: invite,
                                    busy: _busyInviteId == invite.id,
                                    onAccept: () => _respondToInvite(
                                      invite,
                                      action: 'accept',
                                    ),
                                    onDecline: () => _respondToInvite(
                                      invite,
                                      action: 'decline',
                                    ),
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                MechaPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Session Controls',
                        style: AppTextStyles.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      const Text(
                        'Use a local logout for this device, or revoke every active refresh token server-side.',
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ResponsiveActionGroup(
                        children: [
                          MechaButton(
                            label: _loggingOut ? 'PROCESSING...' : 'LOGOUT',
                            variant: MechaButtonVariant.outlined,
                            onTap: _loggingOut
                                ? null
                                : () => _logout(allSessions: false),
                          ),
                          MechaButton(
                            label: _loggingOut
                                ? 'PROCESSING...'
                                : 'LOGOUT ALL SESSIONS',
                            onTap: _loggingOut
                                ? null
                                : () => _logout(allSessions: true),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({
    required this.invite,
    required this.busy,
    required this.onAccept,
    required this.onDecline,
  });

  final ProjectInvite invite;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final projectName = invite.project?.name ?? 'Unknown project';
    final inviterName = invite.inviter?.resolvedDisplayName ??
        invite.inviter?.username ??
        'Owner';

    return MechaPanel(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(projectName, style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Invited by $inviterName as ${titleCaseToken(invite.role)}.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Received ${formatShortDate(invite.createdAt)}',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: AppSpacing.md),
          ResponsiveActionGroup(
            breakpoint: 560,
            children: [
              MechaButton(
                label: busy ? 'PROCESSING...' : 'ACCEPT',
                onTap: busy ? null : onAccept,
              ),
              MechaButton(
                label: busy ? 'PROCESSING...' : 'DECLINE',
                variant: MechaButtonVariant.outlined,
                onTap: busy ? null : onDecline,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
