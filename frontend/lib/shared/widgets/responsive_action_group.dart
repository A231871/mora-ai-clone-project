import 'package:flutter/material.dart';

import '../../core/constants/app_spacing.dart';

class ResponsiveActionGroup extends StatelessWidget {
  const ResponsiveActionGroup({
    super.key,
    required this.children,
    this.breakpoint = 640,
  });

  final List<Widget> children;
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index < children.length - 1)
                  const SizedBox(height: AppSpacing.sm),
              ],
            ],
          );
        }

        return Row(
          children: [
            for (var index = 0; index < children.length; index++) ...[
              Expanded(child: children[index]),
              if (index < children.length - 1)
                const SizedBox(width: AppSpacing.sm),
            ],
          ],
        );
      },
    );
  }
}
