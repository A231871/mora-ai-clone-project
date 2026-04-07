import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import 'grid_background.dart';
import 'mecha_app_bar.dart';

class WorkspaceScreenShell extends StatelessWidget {
  const WorkspaceScreenShell({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.floatingActionButton,
    this.showBack = true,
    this.padding = const EdgeInsets.all(AppSpacing.md),
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final Widget? floatingActionButton;
  final bool showBack;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: MechaAppBar(
        title: title,
        trailing: trailing,
        showBack: showBack,
      ),
      floatingActionButton: floatingActionButton,
      body: Stack(
        children: [
          const GridBackground(),
          SafeArea(
            top: false,
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
