import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_strings.dart';

/// Reusable transparent app bar for Chat / Reminders / Config screens.
class MechaAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MechaAppBar({
    super.key,
    required this.title,
    this.trailing,
    this.showBack = true,
  });

  final String title;
  final Widget? trailing;
  final bool showBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: showBack
          ? TextButton(
              onPressed: () => context.pop(),
              child: Text(
                AppStrings.back,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            )
          : null,
      title: Text(title, style: AppTextStyles.titleMedium),
      centerTitle: true,
      actions: [
        if (trailing != null)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: trailing,
          ),
      ],
    );
  }
}
