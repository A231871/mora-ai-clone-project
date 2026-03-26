import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/grid_background.dart';
import '../../../shared/widgets/mecha_app_bar.dart';
import '../../../shared/widgets/mecha_button.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  double _masterVol = 0.75;
  double _effectVol = 0.50;
  String _selectedVoice = 'Voice A';

  final Map<String, bool> _toggles = {
    AppStrings.darkMode:       true,
    AppStrings.notifications:  true,
    AppStrings.moraVoice:      true,
    AppStrings.hapticFeedback: false,
    AppStrings.privacyShield:  true,
  };

  final Map<String, String> _toggleSubs = {
    AppStrings.darkMode:       AppStrings.darkModeSub,
    AppStrings.notifications:  AppStrings.notificationsSub,
    AppStrings.moraVoice:      AppStrings.moraVoiceSub,
    AppStrings.hapticFeedback: AppStrings.hapticSub,
    AppStrings.privacyShield:  AppStrings.privacySub,
  };

  final Map<String, IconData> _toggleIcons = {
    AppStrings.darkMode:       Icons.dark_mode_outlined,
    AppStrings.notifications:  Icons.notifications_outlined,
    AppStrings.moraVoice:      Icons.mic_outlined,
    AppStrings.hapticFeedback: Icons.vibration_outlined,
    AppStrings.privacyShield:  Icons.shield_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: const MechaAppBar(title: AppStrings.systemControl),
      body: Stack(
        children: [
          const GridBackground(),
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── AUDIO SYSTEMS ──────────────────────────────────────
                _SectionLabel(AppStrings.audioSystems),

                _SliderCard(
                  label: AppStrings.masterVolume,
                  value: _masterVol,
                  onChanged: (v) => setState(() => _masterVol = v),
                ),
                const SizedBox(height: AppSpacing.sm),
                _SliderCard(
                  label: AppStrings.effectVolume,
                  value: _effectVol,
                  onChanged: (v) => setState(() => _effectVol = v),
                ),

                const SizedBox(height: AppSpacing.lg),

                // ── VOICE SELECTION ────────────────────────────────────
                _SectionLabel(AppStrings.voiceSelection),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(AppSpacing.md),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppStrings.morasVoice,
                          style: AppTextStyles.titleMedium),
                      DropdownButton<String>(
                        value: _selectedVoice,
                        dropdownColor: AppColors.bgCard,
                        underline: const SizedBox(),
                        style: AppTextStyles.bodyMedium,
                        items: ['Voice A', 'Voice B']
                            .map((v) => DropdownMenuItem(
                                  value: v,
                                  child: Text(v),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedVoice = v ?? _selectedVoice),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // ── SYSTEM CONTROLS ────────────────────────────────────
                _SectionLabel(AppStrings.systemControls),

                ..._toggles.entries.map((entry) => _ToggleCard(
                      key: ValueKey(entry.key),
                      title: entry.key,
                      subtitle: _toggleSubs[entry.key] ?? '',
                      icon: _toggleIcons[entry.key] ?? Icons.settings,
                      value: entry.value,
                      onChanged: (v) =>
                          setState(() => _toggles[entry.key] = v),
                    )),

                const SizedBox(height: AppSpacing.xl),

                // ── SESSION WARNING ────────────────────────────────────
                const Center(
                  child: Text(AppStrings.sessionWarning,
                      style: AppTextStyles.caption),
                ),

                const SizedBox(height: AppSpacing.md),

                // ── EXIT TO START ──────────────────────────────────────
                MechaButton(
                  label: AppStrings.exitToStart,
                  onTap: () => context.go('/'),
                ),

                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section label ──────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(label, style: AppTextStyles.sectionLabel),
    );
  }
}

// ── Slider card ────────────────────────────────────────────────────────────────
class _SliderCard extends StatelessWidget {
  const _SliderCard({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Text(label, style: AppTextStyles.titleMedium),
          Expanded(
            child: Slider(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primary,
              inactiveColor: AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Toggle card ────────────────────────────────────────────────────────────────
class _ToggleCard extends StatelessWidget {
  const _ToggleCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleMedium),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.textPrimary,
            activeTrackColor: AppColors.primary,
            inactiveThumbColor: AppColors.textSecondary,
            inactiveTrackColor: AppColors.bgCard,
          ),
        ],
      ),
    );
  }
}
