import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import 'mecha_button.dart';
import 'mecha_panel.dart';

class WorkspaceEmptyState extends StatelessWidget {
  const WorkspaceEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.adaptiveToConstraints = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool adaptiveToConstraints;

  static const double _compactHeightThreshold = 260;

  @override
  Widget build(BuildContext context) {
    if (!adaptiveToConstraints) {
      return _buildPanel(compact: false);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedHeight || !constraints.maxHeight.isFinite) {
          return _buildPanel(compact: false);
        }

        final useCompactLayout =
            constraints.maxHeight < _compactHeightThreshold;
        final panel = SizedBox(
          width: constraints.maxWidth,
          child: _buildPanel(compact: useCompactLayout),
        );
        final content = ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Align(
            alignment:
                useCompactLayout ? Alignment.topCenter : Alignment.center,
            child: panel,
          ),
        );

        return SingleChildScrollView(child: content);
      },
    );
  }

  Widget _buildPanel({required bool compact}) {
    final iconSize = compact ? 34.0 : 42.0;
    final topSpacing = compact ? AppSpacing.sm : AppSpacing.md;
    final actionSpacing = compact ? AppSpacing.sm : AppSpacing.md;
    final verticalPadding = compact ? AppSpacing.sm : AppSpacing.md;

    return MechaPanel(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: verticalPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: AppColors.primary),
          SizedBox(height: topSpacing),
          Text(
            title,
            style: AppTextStyles.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            SizedBox(height: actionSpacing),
            MechaButton(
              label: actionLabel!,
              onTap: onAction!,
            ),
          ],
        ],
      ),
    );
  }
}
