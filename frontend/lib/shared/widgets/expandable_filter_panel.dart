import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import 'mecha_panel.dart';

class ExpandableFilterPanel extends StatelessWidget {
  const ExpandableFilterPanel({
    super.key,
    required this.title,
    required this.summary,
    required this.expanded,
    required this.onExpandedChanged,
    required this.child,
    this.collapsedHint = 'Tap to expand search and filters',
    this.collapseBreakpoint = 720,
    this.compactExpandedBodyMaxHeight = 320,
  });

  final String title;
  final String summary;
  final bool expanded;
  final ValueChanged<bool> onExpandedChanged;
  final Widget child;
  final String collapsedHint;
  final double collapseBreakpoint;
  final double compactExpandedBodyMaxHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < collapseBreakpoint;
        final isExpanded = !isCompact || expanded;
        final effectiveSummary =
            summary.trim().isEmpty ? collapsedHint : summary;
        final screenHeight = MediaQuery.sizeOf(context).height;
        final compactBodyMaxHeight = math.min(
          compactExpandedBodyMaxHeight,
          math.max(200.0, screenHeight * 0.34),
        );

        return MechaPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(AppRadius.md),
                onTap: isCompact ? () => onExpandedChanged(!expanded) : null,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: AppTextStyles.titleMedium),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            effectiveSummary,
                            maxLines: isExpanded ? 3 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (isCompact) ...[
                      const SizedBox(width: AppSpacing.md),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.28),
                          ),
                        ),
                        child: Icon(
                          isExpanded ? Icons.expand_less : Icons.tune,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isExpanded) ...[
                const SizedBox(height: AppSpacing.md),
                if (isCompact)
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: compactBodyMaxHeight,
                    ),
                    child: SingleChildScrollView(child: child),
                  )
                else
                  child,
              ],
            ],
          ),
        );
      },
    );
  }
}
