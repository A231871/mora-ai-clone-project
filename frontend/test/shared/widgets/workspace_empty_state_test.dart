import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/constants/app_spacing.dart';
import 'package:frontend/shared/widgets/expandable_filter_panel.dart';
import 'package:frontend/shared/widgets/workspace_empty_state.dart';

void main() {
  Future<void> pumpHarness(
    WidgetTester tester, {
    required Widget child,
    Size size = const Size(360, 640),
  }) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(size);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: child,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'adaptive empty state fits within a tight height without an action',
    (tester) async {
      await pumpHarness(
        tester,
        child: const SizedBox(
          height: 220,
          child: WorkspaceEmptyState(
            icon: Icons.search_off,
            title: 'No Results',
            message: 'Try another filter.',
            adaptiveToConstraints: true,
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('No Results'), findsOneWidget);
    },
  );

  testWidgets(
    'adaptive empty state fits within a tight height with an action button',
    (tester) async {
      await pumpHarness(
        tester,
        child: SizedBox(
          height: 220,
          child: WorkspaceEmptyState(
            icon: Icons.add_task_outlined,
            title: 'No Tasks Found',
            message:
                'Adjust the filters or create a task from the admin console.',
            actionLabel: 'Create Task',
            onAction: () {},
            adaptiveToConstraints: true,
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Create Task'), findsOneWidget);
    },
  );

  testWidgets(
    'adaptive empty state stays safe in medium constrained height',
    (tester) async {
      await pumpHarness(
        tester,
        child: const SizedBox(
          height: 300,
          child: WorkspaceEmptyState(
            icon: Icons.assignment_outlined,
            title: 'No Tasks Found',
            message:
                'Adjust the filters or create a task from the admin console.',
            adaptiveToConstraints: true,
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('No Tasks Found'), findsOneWidget);
    },
  );

  testWidgets(
    'collapsed filter panel stays collapsed in bounded height',
    (tester) async {
      await pumpHarness(
        tester,
        child: const SizedBox(
          height: 300,
          child: ExpandableFilterPanel(
            title: 'Search & Filters',
            summary: 'Tap to search and filter tags.',
            expanded: false,
            onExpandedChanged: _noopExpandedChanged,
            child: Text('INNER FILTER CONTENT'),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('INNER FILTER CONTENT'), findsNothing);
      expect(find.byIcon(Icons.tune), findsOneWidget);
      expect(find.byIcon(Icons.expand_less), findsNothing);
    },
  );

  testWidgets(
    'expanded filter panel above adaptive empty state builds without overflow on compact height',
    (tester) async {
      await pumpHarness(
        tester,
        size: const Size(360, 620),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExpandableFilterPanel(
              title: 'Search & Filters',
              summary: 'Status In Progress',
              expanded: true,
              onExpandedChanged: (_) {},
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TextField(
                    decoration: InputDecoration(
                      hintText: 'Search task title or description',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      Chip(label: Text('ALL PROJECTS')),
                      Chip(label: Text('IN PROGRESS')),
                      Chip(label: Text('HIGH')),
                      Chip(label: Text('MINE')),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: 'recent',
                    items: const [
                      DropdownMenuItem(
                        value: 'recent',
                        child: Text('RECENT ACTIVITY'),
                      ),
                      DropdownMenuItem(
                        value: 'priority',
                        child: Text('PRIORITY'),
                      ),
                    ],
                    onChanged: null,
                    decoration: const InputDecoration(labelText: 'Sort'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Expanded(
              child: WorkspaceEmptyState(
                icon: Icons.assignment_outlined,
                title: 'No Tasks Found',
                message:
                    'Adjust the filters or create a task from the admin console.',
                adaptiveToConstraints: true,
              ),
            ),
          ],
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('No Tasks Found'), findsOneWidget);
    },
  );
}

void _noopExpandedChanged(bool _) {}
