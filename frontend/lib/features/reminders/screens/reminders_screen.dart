import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/grid_background.dart';
import '../../../shared/widgets/mecha_app_bar.dart';
import '../../../shared/widgets/status_chip.dart';
import '../models/task.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final List<Task> _tasks = [
    Task(
      id: '1',
      title: '3:00 PM Team Meeting',
      category: AppStrings.categoryWork,
      time: '15:00',
      frequency: 'Today',
      isFeatured: true,
    ),
    Task(
      id: '2',
      title: 'Take afternoon vitamins',
      category: AppStrings.categoryHealth,
      time: '13:00',
      frequency: 'Daily',
      isDone: true,
    ),
    Task(
      id: '3',
      title: "Review Mora's new features",
      category: AppStrings.categoryMora,
      time: '18:30',
      frequency: 'Today',
    ),
    Task(
      id: '4',
      title: 'Call back Sakura-chan',
      category: AppStrings.categorySocial,
      time: '20:00',
      frequency: 'Today',
    ),
  ];

  Color _chipColor(String category) {
    switch (category) {
      case AppStrings.categoryWork:   return AppColors.chipWork;
      case AppStrings.categoryHealth: return AppColors.chipHealth;
      case AppStrings.categoryMora:   return AppColors.chipMora;
      case AppStrings.categorySocial: return AppColors.chipSocial;
      default: return AppColors.primary;
    }
  }

  int get _doneCount => _tasks.where((t) => t.isDone).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: MechaAppBar(
        title: AppStrings.remindersTitle,
        trailing: Text(
          '${_doneCount}/${_tasks.length} DONE',
          style: AppTextStyles.caption
              .copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.addReminderSnack,
                style: AppTextStyles.bodyMedium),
            backgroundColor: AppColors.bgCard,
          ),
        ),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.textPrimary),
      ),
      body: Stack(
        children: [
          const GridBackground(),
          Column(
            children: [
              // ── Progress bar ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: _tasks.isEmpty ? 0 : _doneCount / _tasks.length,
                    minHeight: 4,
                    backgroundColor: AppColors.bgCard,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // ── Task list ─────────────────────────────────────────────
              Expanded(
                child: _tasks.isEmpty
                    ? const Center(
                        child: Text(AppStrings.noRemindersYet,
                            style: AppTextStyles.hint),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md),
                        itemCount: _tasks.length,
                        itemBuilder: (_, i) => _TaskCard(
                          task: _tasks[i],
                          chipColor: _chipColor(_tasks[i].category),
                          onToggle: () =>
                              setState(() => _tasks[i].isDone = !_tasks[i].isDone),
                          onDelete: () =>
                              setState(() => _tasks.removeAt(i)),
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Task card ──────────────────────────────────────────────────────────────────
class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.chipColor,
    required this.onToggle,
    required this.onDelete,
  });

  final Task task;
  final Color chipColor;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // ── Circle checkbox ─────────────────────────────────────────
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: task.isDone
                    ? AppColors.primary
                    : Colors.transparent,
                border: Border.all(
                  color: AppColors.primary,
                  width: 2,
                ),
                boxShadow: task.isDone
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 8,
                        )
                      ]
                    : null,
              ),
              child: task.isDone
                  ? const Icon(Icons.check,
                      size: 16, color: AppColors.textPrimary)
                  : null,
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          // ── Task details ────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatusChip(label: task.category, color: chipColor),
                    if (task.isFeatured) ...[
                      const SizedBox(width: AppSpacing.xs),
                      const Icon(Icons.star,
                          size: 14, color: AppColors.primary),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  task.title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    decoration: task.isDone
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    color: task.isDone
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.access_time_outlined,
                        size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${task.time} · ${task.frequency}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Delete icon ─────────────────────────────────────────────
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline,
                size: 18, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
