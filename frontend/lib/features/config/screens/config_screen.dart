import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/language_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/grid_background.dart';
import '../../../shared/widgets/mecha_app_bar.dart';
import '../../../shared/widgets/mecha_button.dart';
import '../../../core/services/voice_service.dart';
import '../../../core/services/audio_service.dart';

class ConfigScreen extends ConsumerStatefulWidget {
  const ConfigScreen({super.key});

  @override
  ConsumerState<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends ConsumerState<ConfigScreen> {
  double _masterVol = 0.75;
  double _effectVol = 0.50; // We keep _effectVol but we'll rename its label if it wasn't voice, wait, we'll map _effectVol to Voice Volume and _masterVol to AudioService
  String _selectedVoice = 'Voice A';

  final VoiceService _voiceService = VoiceService();
  final AudioService _audioService = AudioService();

  final Map<String, bool> _togglesStates = {
    'darkMode':       true,
    'notifications':  true,
    'shizukiVoice':    true,
    'hapticFeedback': false,
    'privacyShield':  true,
  };

  @override
  void initState() {
    super.initState();
    _voiceService.init();
    _audioService.init();
  }

void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.bgDeep.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.md),
            side: const BorderSide(color: Colors.redAccent, width: 2),
          ),
          title: Row(
            children:[
              const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
              const SizedBox(width: AppSpacing.sm),
              // ADDED EXPANDED HERE TO FIX THE ROW OVERFLOW
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'SYSTEM DISCONNECT',
                    style: AppTextStyles.titleLarge.copyWith(color: Colors.redAccent),
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to disconnect?\nActive session will be terminated.',
            style: AppTextStyles.bodyMedium,
          ),
          actions:[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('CANCEL', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
            ),
            MechaButton(
              label: 'DISCONNECT',
              onTap: () {
                Navigator.pop(dialogContext); // dismiss dialog
                context.go('/'); // wipe session & route to login
              },
            ),
          ],
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: MechaAppBar(title: AppLocalizations.of(context)!.systemControl),
      body: Stack(
        children:[
          const GridBackground(),
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:[
                // ── LANGUAGE SELECTION ─────────────────────────────────
                _SectionLabel('LANGUAGE / NGÔN NGỮ'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(AppSpacing.md),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('System Language', style: AppTextStyles.titleMedium),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'en', label: Text('EN')),
                          ButtonSegment(value: 'vi', label: Text('VI')),
                        ],
                        selected: {currentLocale.languageCode},
                        onSelectionChanged: (Set<String> newSelection) {
                          ref.read(languageProvider.notifier).setLanguage(newSelection.first);
                        },
                        style: SegmentedButton.styleFrom(
                          backgroundColor: AppColors.bgDeep,
                          selectedBackgroundColor: AppColors.primary.withOpacity(0.2),
                          foregroundColor: AppColors.textPrimary,
                          selectedForegroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── AUDIO SYSTEMS ──────────────────────────────────────
                _SectionLabel(loc.audioSystems),

                _SliderCard(
                  label: loc.masterVolume,
                  value: _masterVol,
                  onChanged: (v) {
                    setState(() => _masterVol = v);
                    _audioService.setMasterVolume(v);
                  },
                  onChangeEnd: (v) {
                    _audioService.playBeep();
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                _SliderCard(
                  label: loc.effectVolume,
                  value: _effectVol,
                  onChanged: (v) {
                    setState(() => _effectVol = v);
                    _voiceService.setVolume(v);
                  },
                  onChangeEnd: (v) {
                    _voiceService.speak(loc.effectVolume); // Or any test string
                  },
                ),

                const SizedBox(height: AppSpacing.lg),

                // ── VOICE SELECTION ────────────────────────────────────
                _SectionLabel(loc.voiceSelection),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(AppSpacing.md),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children:[
                      Text(loc.shizukisVoice,
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
                _SectionLabel(loc.systemControls),

                ..._toggles.map((t) => _ToggleCard(
                      key: ValueKey(t['id']),
                      title: t['title'],
                      subtitle: t['sub'],
                      icon: t['icon'],
                      value: _togglesStates[t['id']] ?? false,
                      onChanged: (v) =>
                          setState(() => _togglesStates[t['id'] as String] = v),
                    )),

                const SizedBox(height: AppSpacing.xl),

                // ── SESSION WARNING ────────────────────────────────────
                Center(
                  child: Text(loc.sessionWarning,
                      style: AppTextStyles.caption),
                ),

                const SizedBox(height: AppSpacing.md),

                // ── EXIT TO START ──────────────────────────────────────
                MechaButton(
                  label: loc.exitToStart,
                  onTap: () => _showLogoutDialog(context),
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
  _SectionLabel(this.label);
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
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children:[
          Text(label, style: AppTextStyles.titleMedium),
          Expanded(
            child: Slider(
              value: value,
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
              activeColor: AppColors.primary,
              inactiveColor: AppColors.primary.withOpacity(0.2),
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
          color: AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children:[
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:[
                Text(title, style: AppTextStyles.titleMedium),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.textPrimary,
            activeTrackColor: AppColors.primary,
            inactiveThumbColor: AppColors.textSecondary,
            inactiveTrackColor: AppColors.bgCard,
          ),
        ],
      ),
    );
  }
}