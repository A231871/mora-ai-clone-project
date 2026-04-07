import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/services/app_settings_service.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/voice_service.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/workspace_models.dart';
import '../../../shared/widgets/mecha_button.dart';
import '../../../shared/widgets/mecha_panel.dart';
import '../../../shared/widgets/responsive_action_group.dart';
import '../../../shared/widgets/workspace_screen_shell.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/services/session_storage.dart';

class ConfigScreen extends ConsumerStatefulWidget {
  const ConfigScreen({super.key});

  @override
  ConsumerState<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends ConsumerState<ConfigScreen> {
  final AudioService _audioService = AudioService();
  final VoiceService _voiceService = VoiceService();
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();

  double _masterVolume = 0.75;
  double _voiceVolume = 0.5;
  bool _notificationsEnabled = true;
  bool _voiceEnabled = true;
  bool _loading = true;
  bool _loggingOut = false;
  AppUser? _currentUser;
  PermissionStatus _notificationPermission = PermissionStatus.denied;
  PermissionStatus _microphonePermission = PermissionStatus.denied;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _loading = true);
    try {
      await Future.wait<void>([
        _audioService.init(),
        _voiceService.init(),
      ]);

      final results = await Future.wait<dynamic>([
        AppSettingsService.instance.getMasterVolume(),
        AppSettingsService.instance.getVoiceVolume(),
        AppSettingsService.instance.getNotificationsEnabled(),
        AppSettingsService.instance.getShizukiVoiceEnabled(),
        SessionStorage.getCurrentUser(),
        _notificationService.getPermissionStatus(),
        Permission.microphone.status,
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _masterVolume = results[0] as double;
        _voiceVolume = results[1] as double;
        _notificationsEnabled = results[2] as bool;
        _voiceEnabled = results[3] as bool;
        _currentUser = results[4] as AppUser?;
        _notificationPermission = results[5] as PermissionStatus;
        _microphonePermission = results[6] as PermissionStatus;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      _showMessage('Failed to load settings: $error');
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    try {
      await _notificationService.setEnabled(value);
      final permission = await _notificationService.getPermissionStatus();
      if (!mounted) {
        return;
      }
      setState(() => _notificationPermission = permission);
      if (value && !permission.isGranted) {
        _showMessage(
          'Notifications are enabled in-app, but OS permission is still blocked.',
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _notificationsEnabled = !value);
      _showMessage('Notification update failed: $error');
    }
  }

  Future<void> _toggleVoice(bool value) async {
    setState(() => _voiceEnabled = value);
    try {
      await _voiceService.setEnabled(value);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _voiceEnabled = !value);
      _showMessage('Voice update failed: $error');
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

  Future<void> _refreshPermissions() async {
    final notificationPermission =
        await _notificationService.getPermissionStatus();
    final microphonePermission = await Permission.microphone.status;
    if (!mounted) {
      return;
    }
    setState(() {
      _notificationPermission = notificationPermission;
      _microphonePermission = microphonePermission;
    });
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

  String _permissionLabel(PermissionStatus status) {
    if (status.isGranted) {
      return 'Granted';
    }
    if (status.isPermanentlyDenied) {
      return 'Blocked';
    }
    if (status.isDenied) {
      return 'Denied';
    }
    if (status.isRestricted) {
      return 'Restricted';
    }
    if (status.isLimited) {
      return 'Limited';
    }
    return 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(languageProvider);

    return WorkspaceScreenShell(
      title: 'System Settings',
      trailing: IconButton(
        onPressed: _loading ? null : _loadSettings,
        icon: const Icon(Icons.refresh, color: AppColors.primary),
      ),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                MechaPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Language', style: AppTextStyles.titleMedium),
                      const SizedBox(height: AppSpacing.sm),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final picker = SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'en', label: Text('EN')),
                              ButtonSegment(value: 'vi', label: Text('VI')),
                            ],
                            selected: {currentLocale.languageCode},
                            onSelectionChanged: (selection) {
                              ref
                                  .read(languageProvider.notifier)
                                  .setLanguage(selection.first);
                            },
                            style: SegmentedButton.styleFrom(
                              backgroundColor: AppColors.bgDeep,
                              selectedBackgroundColor:
                                  AppColors.primary.withValues(alpha: 0.2),
                              foregroundColor: AppColors.textPrimary,
                              selectedForegroundColor: AppColors.primary,
                            ),
                          );

                          if (constraints.maxWidth < 520) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'System language persists across restarts.',
                                  style: AppTextStyles.bodySmall,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                picker,
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'System language persists across restarts.',
                                  style: AppTextStyles.bodySmall,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              picker,
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                MechaPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Audio', style: AppTextStyles.titleMedium),
                      const SizedBox(height: AppSpacing.md),
                      _SettingsSliderCard(
                        label: 'Master Volume',
                        value: _masterVolume,
                        onChanged: (value) {
                          setState(() => _masterVolume = value);
                          unawaited(_audioService.setMasterVolume(value));
                        },
                        onChangeEnd: (_) => unawaited(_audioService.playBeep()),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _SettingsSliderCard(
                        label: 'Shizuki Voice Volume',
                        value: _voiceVolume,
                        onChanged: (value) {
                          setState(() => _voiceVolume = value);
                          unawaited(_voiceService.setVolume(value));
                        },
                        onChangeEnd: (_) {
                          final languageCode =
                              ref.read(languageProvider).languageCode;
                          unawaited(
                            _voiceService.speak(
                              'Voice output ready.',
                              languageCode: languageCode,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                MechaPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Runtime Toggles', style: AppTextStyles.titleMedium),
                      const SizedBox(height: AppSpacing.md),
                      _SettingsSwitchTile(
                        title: 'Notifications',
                        subtitle:
                            'Controls whether reminder notifications are scheduled locally.',
                        value: _notificationsEnabled,
                        onChanged: (value) {
                          unawaited(_toggleNotifications(value));
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _SettingsSwitchTile(
                        title: 'Shizuki Voice',
                        subtitle:
                            'Controls whether AI replies and home-screen lines are spoken aloud.',
                        value: _voiceEnabled,
                        onChanged: (value) {
                          unawaited(_toggleVoice(value));
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                MechaPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Status',
                              style: AppTextStyles.titleMedium,
                            ),
                          ),
                          TextButton(
                            onPressed: _refreshPermissions,
                            child: Text(
                              'REFRESH',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _currentUser == null
                            ? 'No active local session loaded.'
                            : 'Signed in as ${_currentUser!.resolvedDisplayName} (@${_currentUser!.username}).',
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          _StatusPill(
                            label:
                                'Session ${_currentUser == null ? 'Missing' : 'Active'}',
                          ),
                          _StatusPill(
                            label:
                                'Notifications ${_permissionLabel(_notificationPermission)}',
                          ),
                          _StatusPill(
                            label:
                                'Microphone ${_permissionLabel(_microphonePermission)}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                MechaPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Session Controls',
                          style: AppTextStyles.titleMedium),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'These actions revoke the current device session or every active refresh session on the backend.',
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

class _SettingsSliderCard extends StatelessWidget {
  const _SettingsSliderCard({
    required this.label,
    required this.value,
    required this.onChanged,
    this.onChangeEnd,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgDeep,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
              Text(
                '${(value * 100).round()}%',
                style: AppTextStyles.caption,
              ),
            ],
          ),
          Slider(
            value: value,
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.primary.withValues(alpha: 0.2),
          ),
        ],
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.bgDeep,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(subtitle, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary,
            activeThumbColor: AppColors.textPrimary,
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Text(label, style: AppTextStyles.caption),
    );
  }
}
