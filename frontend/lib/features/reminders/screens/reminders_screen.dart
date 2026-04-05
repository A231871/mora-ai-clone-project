import 'package:frontend/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/grid_background.dart';
import '../../../shared/widgets/mecha_app_bar.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/services/notification_service.dart';
import '../models/task.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  StreamSubscription? _notificationSub;

  @override
  void initState() {
    super.initState();

    _notificationSub = ChatService().pendingRemindersStream.listen((data) {
      if (mounted) {
        final loc = AppLocalizations.of(context)!;
        final currentTasks = data.map((e) => Task.fromJson(Map<String, dynamic>.from(e as Map))).toList();
        for (final task in currentTasks) {
          if (!task.isDone) {
            DateTime? schedule;
            if (task.isoTime.isNotEmpty) {
               schedule = DateTime.tryParse(task.isoTime)?.toLocal();
            }
            if (schedule != null) {
              NotificationService().scheduleReminderNotification(
                mongoId: task.id,
                title: loc.notificationTaskTitle,
                body: task.title,
                time: schedule,
                daysOfWeek: task.daysOfWeek,
              );
            }
          }
        }
      }
    });

    _connectAndSyncReminders();
  }

  Future<void> _connectAndSyncReminders() async {
    try {
      await ChatService().connect();
    } catch (e) {
      debugPrint('[RemindersScreen] Socket connect failed: $e');
    }
    if (!mounted) return;
    ChatService().fetchPendingReminders();
  }

  @override
  void dispose() {
    _notificationSub?.cancel();
    super.dispose();
  }

  Future<void> _confirmDeleteAll(BuildContext context, List<Task> currentTasks) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: Colors.redAccent, width: 2),
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        title: Row(
          children:[
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            const SizedBox(width: AppSpacing.sm),
            Text('SYSTEM PURGE', style: AppTextStyles.titleMedium.copyWith(color: Colors.redAccent)),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete all reminders?\n\nThis action cannot be undone.',
          style: AppTextStyles.bodyMedium,
        ),
        actions:[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL', style: AppTextStyles.caption),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('PURGE', style: AppTextStyles.caption.copyWith(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Cancel all local notifications by iterating through known tasks
      for (final task in currentTasks) {
        NotificationService().cancelReminderNotifications(task.id, previousDaysOfWeek: task.daysOfWeek);
      }
      ChatService().deleteAllReminders();
    }
  }

  Future<void> _showAddEditReminderDialog(BuildContext context, {Task? existingTask}) async {
    final titleCtrl = TextEditingController(text: existingTask?.title ?? '');
    TimeOfDay? selectedTime;
    if (existingTask != null && existingTask.isoTime.isNotEmpty) {
      final t = DateTime.tryParse(existingTask.isoTime)?.toLocal();
      if (t != null) selectedTime = TimeOfDay.fromDateTime(t);
    }
    
    List<String> selectedDays = List.from(existingTask?.daysOfWeek ??[]);
    final daysOfWeek =['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.bgCard,
            title: Text(existingTask == null ? 'NEW TASK' : 'EDIT TASK', style: AppTextStyles.titleMedium),
            // WRAPPED THE COLUMN WITH SingleChildScrollView HERE
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children:[
                  TextField(
                    controller: titleCtrl,
                    style: AppTextStyles.bodyMedium,
                    decoration: const InputDecoration(
                      hintText: 'Task title...',
                      hintStyle: AppTextStyles.hint,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ElevatedButton(
                    onPressed: () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: selectedTime ?? TimeOfDay.now(),
                      );
                      if (t != null) {
                        setDialogState(() => selectedTime = t);
                      }
                    },
                    child: Text(
                      selectedTime == null 
                          ? 'SELECT SCHEDULE' 
                          : '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: 4.0,
                    runSpacing: 4.0,
                    alignment: WrapAlignment.center,
                    children: daysOfWeek.map((day) {
                      final isSelected = selectedDays.contains(day);
                      return FilterChip(
                        label: Text(day, style: AppTextStyles.caption.copyWith(
                          color: isSelected ? AppColors.textPrimary : AppColors.textSecondary
                        )),
                        selected: isSelected,
                        selectedColor: AppColors.primary.withValues(alpha: 0.4),
                        backgroundColor: Colors.transparent,
                        shape: StadiumBorder(
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.5)
                          )
                        ),
                        onSelected: (bool selected) {
                          setDialogState(() {
                            if (selected) {
                              selectedDays.add(day);
                            } else {
                              selectedDays.remove(day);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions:[
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('CANCEL', style: AppTextStyles.caption),
              ),
              TextButton(
                onPressed: () {
                  if (titleCtrl.text.isNotEmpty && selectedTime != null) {
                    final now = DateTime.now();
                    DateTime schedule = DateTime(
                      now.year, now.month, now.day,
                      selectedTime!.hour, selectedTime!.minute,
                    );
                    
                    if (schedule.isBefore(now)) {
                      schedule = schedule.add(const Duration(days: 1));
                    }

                    if (existingTask != null) {
                      NotificationService().cancelReminderNotifications(existingTask.id, previousDaysOfWeek: existingTask.daysOfWeek);
                      ChatService().updateReminder(
                        id: existingTask.id,
                        task: titleCtrl.text,
                        isoTime: schedule.toIso8601String(),
                        daysOfWeek: selectedDays,
                      );
                    } else {
                      ChatService().createManualReminder(titleCtrl.text, schedule.toIso8601String(), selectedDays);
                    }
                    
                    Navigator.pop(ctx);
                  }
                },
                child: Text(existingTask == null ? 'CREATE' : 'SAVE', style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
              ),
            ],
          );
        }
      ),
    );
  }
  
  Color _chipColor(String category) {
    final cat = category.toUpperCase();
    if (cat == 'WORK') return AppColors.chipWork;
    if (cat == 'HEALTH') return AppColors.chipHealth;
    if (cat == 'SHIZUKI' || cat == 'MORA') return AppColors.chipMora;
    if (cat == 'SOCIAL') return AppColors.chipSocial;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<dynamic>>(
      stream: ChatService().pendingRemindersStream,
      initialData: ChatService().currentReminders,
      builder: (context, snapshot) {
        final currentTasks = (snapshot.data ??[])
            .map((e) => Task.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        final int doneCount = currentTasks.where((t) => t.isDone).length;

        return Scaffold(
          backgroundColor: AppColors.bgDeep,
          appBar: MechaAppBar(
            title: AppLocalizations.of(context)!.remindersTitle,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children:[
                Text(
                  '$doneCount/${currentTasks.length} DONE',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: AppSpacing.sm),
                IconButton(
                  icon: const Icon(Icons.done_all, color: AppColors.primary),
                  tooltip: 'Complete All',
                  onPressed: () {
                    for (final task in currentTasks) {
                      NotificationService().cancelReminderNotifications(task.id, previousDaysOfWeek: task.daysOfWeek);
                    }
                    ChatService().completeAllReminders();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_sweep, color: AppColors.primary),
                  tooltip: 'Delete All',
                  onPressed: () => _confirmDeleteAll(context, currentTasks),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddEditReminderDialog(context),
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add, color: AppColors.textPrimary),
          ),
          body: Stack(
            children:[
              const GridBackground(),
              Column(
                children:[
                  // ── Progress bar ─────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: LinearProgressIndicator(
                        value: currentTasks.isEmpty ? 0 : doneCount / currentTasks.length,
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
                    child: currentTasks.isEmpty
                        ? Center(
                            child: Text(AppLocalizations.of(context)!.noRemindersYet,
                                style: AppTextStyles.hint),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md),
                            itemCount: currentTasks.length,
                            itemBuilder: (_, i) => _TaskCard(
                              task: currentTasks[i],
                              chipColor: _chipColor(currentTasks[i].category),
                              onToggle: () {
                                if (!currentTasks[i].isDone) {
                                  NotificationService().cancelReminderNotifications(currentTasks[i].id, previousDaysOfWeek: currentTasks[i].daysOfWeek);
                                }
                                ChatService().updateReminder(id: currentTasks[i].id, isCompleted: !currentTasks[i].isDone);
                              },
                              onEdit: () {
                                _showAddEditReminderDialog(context, existingTask: currentTasks[i]);
                              },
                              onDelete: () {
                                NotificationService().cancelReminderNotifications(currentTasks[i].id, previousDaysOfWeek: currentTasks[i].daysOfWeek);
                                ChatService().deleteReminder(currentTasks[i].id);
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        );
      }
    );
  }
}


// ── Task card ──────────────────────────────────────────────────────────────────
class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.chipColor,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final Task task;
  final Color chipColor;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
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
          color: AppColors.primary.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        children:[
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
                    ?[
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
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
                  children:[
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
                  children:[
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

          // ── Action icons ─────────────────────────────────────────────
          Row(
            mainAxisSize: MainAxisSize.min,
            children:[
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined,
                    size: 18, color: AppColors.textSecondary),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}