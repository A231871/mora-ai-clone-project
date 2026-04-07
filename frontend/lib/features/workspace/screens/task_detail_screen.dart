import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/services/api_client.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/workspace_models.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/mecha_button.dart';
import '../../../shared/widgets/mecha_panel.dart';
import '../../../shared/widgets/responsive_action_group.dart';
import '../../../shared/widgets/workspace_empty_state.dart';
import '../../../shared/widgets/workspace_screen_shell.dart';
import '../../auth/services/session_storage.dart';
import '../services/files_service.dart';
import '../services/projects_service.dart';
import '../services/tasks_service.dart';

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({
    super.key,
    required this.projectId,
    required this.taskId,
  });

  final String projectId;
  final String taskId;

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final TasksService _tasksService = TasksService();
  final ProjectsService _projectsService = ProjectsService();
  final FilesService _filesService = FilesService();
  final TextEditingController _commentController = TextEditingController();

  TaskItem? _task;
  WorkspaceProject? _project;
  AppUser? _currentUser;
  List<ProjectMember> _members = const <ProjectMember>[];
  List<ProjectTag> _tags = const <ProjectTag>[];
  List<TaskComment> _comments = const <TaskComment>[];
  bool _loading = true;
  bool _submittingComment = false;
  String? _busyId;

  bool get _canManageContent => _project?.canManageContent ?? false;
  bool get _canComment => _project?.canComment ?? false;
  bool get _memberUiReadOnly => _project?.memberUiReadOnly ?? false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final currentUser = await SessionStorage.getCurrentUser();
      final results = await Future.wait<dynamic>([
        _tasksService.getTask(widget.taskId),
        _projectsService.getProject(widget.projectId),
        _projectsService.listMembers(widget.projectId),
        _projectsService.listTags(widget.projectId),
        _tasksService.listComments(widget.taskId),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _currentUser = currentUser;
        _task = results[0] as TaskItem;
        _project = results[1] as WorkspaceProject;
        _members = results[2] as List<ProjectMember>;
        _tags = results[3] as List<ProjectTag>;
        _comments = results[4] as List<TaskComment>;
        _loading = false;
        _busyId = null;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      _showMessage(error.message);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      _showMessage('Failed to load task detail: $error');
    }
  }

  Future<void> _showTaskEditDialog() async {
    final task = _task;
    if (task == null) {
      return;
    }

    final titleController = TextEditingController(text: task.title);
    final descriptionController = TextEditingController(text: task.description);
    var status = task.status;
    var priority = task.priority;
    var reminderAt = task.reminderAt;
    final selectedAssigneeIds = <String>{...task.assigneeIds};
    final selectedTagIds = <String>{...task.tagIds};

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          title: Text('Update Task', style: AppTextStyles.titleMedium),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  style: AppTextStyles.bodyMedium,
                  decoration: const InputDecoration(hintText: 'Task title'),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: descriptionController,
                  minLines: 3,
                  maxLines: 5,
                  style: AppTextStyles.bodyMedium,
                  decoration:
                      const InputDecoration(hintText: 'Task description'),
                ),
                const SizedBox(height: AppSpacing.md),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 420;
                    final statusField = DropdownButtonFormField<String>(
                      initialValue: status,
                      dropdownColor: AppColors.bgCard,
                      items: const [
                        DropdownMenuItem(value: 'todo', child: Text('TODO')),
                        DropdownMenuItem(
                          value: 'in_progress',
                          child: Text('IN PROGRESS'),
                        ),
                        DropdownMenuItem(value: 'done', child: Text('DONE')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => status = value);
                        }
                      },
                    );

                    final priorityField = DropdownButtonFormField<String>(
                      initialValue: priority,
                      dropdownColor: AppColors.bgCard,
                      items: const [
                        DropdownMenuItem(value: 'low', child: Text('LOW')),
                        DropdownMenuItem(
                          value: 'medium',
                          child: Text('MEDIUM'),
                        ),
                        DropdownMenuItem(value: 'high', child: Text('HIGH')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => priority = value);
                        }
                      },
                    );

                    if (compact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          statusField,
                          const SizedBox(height: AppSpacing.md),
                          priorityField,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: statusField),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: priorityField),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Assignees', style: AppTextStyles.caption),
                const SizedBox(height: AppSpacing.xs),
                if (_members.where((member) => member.user != null).isEmpty)
                  Text(
                    'No accepted project members are available for assignment yet.',
                    style: AppTextStyles.bodySmall,
                  )
                else
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: _members
                        .where((member) => member.user != null)
                        .map(
                          (member) => FilterChip(
                            label: Text(
                              member.user?.resolvedDisplayName ??
                                  member.user?.username ??
                                  member.userId,
                            ),
                            selected:
                                selectedAssigneeIds.contains(member.userId),
                            selectedColor:
                                AppColors.primary.withValues(alpha: 0.22),
                            backgroundColor: AppColors.bgDeep,
                            onSelected: (selected) {
                              setDialogState(() {
                                if (selected) {
                                  selectedAssigneeIds.add(member.userId);
                                } else {
                                  selectedAssigneeIds.remove(member.userId);
                                }
                              });
                            },
                          ),
                        )
                        .toList(growable: false),
                  ),
                const SizedBox(height: AppSpacing.md),
                Text('Tags', style: AppTextStyles.caption),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final tag in _tags)
                      FilterChip(
                        label: Text(tag.name),
                        selected: selectedTagIds.contains(tag.id),
                        selectedColor:
                            AppColors.primary.withValues(alpha: 0.22),
                        backgroundColor: AppColors.bgDeep,
                        onSelected: (selected) {
                          setDialogState(() {
                            if (selected) {
                              selectedTagIds.add(tag.id);
                            } else {
                              selectedTagIds.remove(tag.id);
                            }
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Reminder', style: AppTextStyles.caption),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        reminderAt == null
                            ? 'No reminder linked'
                            : formatShortDateTime(reminderAt),
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                          initialDate: reminderAt ?? DateTime.now(),
                        );
                        if (date == null || !context.mounted) {
                          return;
                        }
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(
                            reminderAt ?? DateTime.now(),
                          ),
                        );
                        if (time == null) {
                          return;
                        }
                        setDialogState(() {
                          reminderAt = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      },
                      icon: const Icon(Icons.alarm_add_outlined),
                    ),
                    if (reminderAt != null)
                      IconButton(
                        onPressed: () =>
                            setDialogState(() => reminderAt = null),
                        icon: const Icon(
                          Icons.alarm_off_outlined,
                          color: Colors.redAccent,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'SAVE',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() => _busyId = task.id);
    try {
      await _tasksService.updateTask(
        task.id,
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        status: status,
        priority: priority,
        assigneeIds: selectedAssigneeIds.toList(growable: false),
        tagIds: selectedTagIds.toList(growable: false),
        reminderAt: reminderAt,
        clearReminder: reminderAt == null && task.reminderAt != null,
      );
      if (!mounted) {
        return;
      }
      _showMessage('Task updated.', isError: false);
      await _loadData();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _busyId = null);
      _showMessage(error.message);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _busyId = null);
      _showMessage('Task update failed: $error');
    }
  }

  Future<void> _showAttachFilesDialog() async {
    final task = _task;
    if (task == null) {
      return;
    }

    List<FileAsset> availableFiles = const <FileAsset>[];
    try {
      availableFiles = await _filesService.listFiles(ownerType: 'unassigned');
    } catch (_) {
      availableFiles = const <FileAsset>[];
    }

    if (!mounted) {
      return;
    }

    final options = <FileAsset>[
      ...task.files,
      ...availableFiles.where((file) => !task.fileIds.contains(file.id)),
    ];
    final selectedIds = <String>{...task.fileIds};

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          title: Text('Attach Files', style: AppTextStyles.titleMedium),
          content: SingleChildScrollView(
            child: options.isEmpty
                ? Text(
                    'No unassigned files are available. Upload assets in Files Vault first.',
                    style: AppTextStyles.bodySmall,
                  )
                : Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final file in options)
                        FilterChip(
                          label: SizedBox(
                            width: 160,
                            child: Text(
                              file.originalName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          selected: selectedIds.contains(file.id),
                          selectedColor:
                              AppColors.primary.withValues(alpha: 0.22),
                          backgroundColor: AppColors.bgDeep,
                          onSelected: (selected) {
                            setDialogState(() {
                              if (selected) {
                                selectedIds.add(file.id);
                              } else {
                                selectedIds.remove(file.id);
                              }
                            });
                          },
                        ),
                    ],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'SAVE',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() => _busyId = task.id);
    try {
      await _tasksService.updateTask(
        task.id,
        fileIds: selectedIds.toList(growable: false),
      );
      if (!mounted) {
        return;
      }
      _showMessage('File attachments updated.', isError: false);
      await _loadData();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _busyId = null);
      _showMessage(error.message);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _busyId = null);
      _showMessage('Attachment update failed: $error');
    }
  }

  Future<void> _deleteTask() async {
    final task = _task;
    if (task == null) {
      return;
    }

    setState(() => _busyId = task.id);
    try {
      await _tasksService.deleteTask(task.id);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _busyId = null);
      _showMessage(error.message);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _busyId = null);
      _showMessage('Delete failed: $error');
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) {
      return;
    }

    setState(() => _submittingComment = true);
    try {
      await _tasksService.createComment(widget.taskId, content: text);
      if (!mounted) {
        return;
      }
      _commentController.clear();
      setState(() => _submittingComment = false);
      await _loadData();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _submittingComment = false);
      _showMessage(error.message);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _submittingComment = false);
      _showMessage('Comment failed: $error');
    }
  }

  Future<void> _showCommentEditDialog(TaskComment comment) async {
    final controller = TextEditingController(text: comment.content);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: Text('Edit Comment', style: AppTextStyles.titleMedium),
        content: TextField(
          controller: controller,
          minLines: 3,
          maxLines: 6,
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'SAVE',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() => _busyId = comment.id);
    try {
      await _tasksService.updateComment(
        widget.taskId,
        comment.id,
        content: controller.text.trim(),
      );
      if (!mounted) {
        return;
      }
      await _loadData();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _busyId = null);
      _showMessage(error.message);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _busyId = null);
      _showMessage('Comment update failed: $error');
    }
  }

  Future<void> _deleteComment(TaskComment comment) async {
    setState(() => _busyId = comment.id);
    try {
      await _tasksService.deleteComment(widget.taskId, comment.id);
      if (!mounted) {
        return;
      }
      await _loadData();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _busyId = null);
      _showMessage(error.message);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _busyId = null);
      _showMessage('Comment delete failed: $error');
    }
  }

  bool _canManageComment(TaskComment comment) {
    return _currentUser?.id == comment.authorId || _canManageContent;
  }

  void _showMessage(String message, {bool isError = true}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.bgCard,
        content: Text(
          message,
          style: TextStyle(
            color: isError ? Colors.redAccent : Colors.greenAccent,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final task = _task;

    return WorkspaceScreenShell(
      title: task?.title ?? 'Task Detail',
      trailing: IconButton(
        onPressed: _loading ? null : _loadData,
        icon: const Icon(Icons.refresh, color: AppColors.primary),
      ),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : task == null
              ? const Center(
                  child: WorkspaceEmptyState(
                    icon: Icons.error_outline,
                    title: 'Task Missing',
                    message: 'This task could not be loaded.',
                  ),
                )
              : ListView(
                  children: [
                    MechaPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(task.title, style: AppTextStyles.displayMedium),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            task.description.isEmpty
                                ? 'No task description.'
                                : task.description,
                            style: AppTextStyles.bodySmall,
                          ),
                          if (task.assignees.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.md),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: task.assignees
                                  .map(
                                    (assignee) => _MetaBadge(
                                      label:
                                          'ASSIGNEE ${assignee.resolvedDisplayName.toUpperCase()}',
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.md),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              _MetaBadge(
                                label:
                                    titleCaseToken(task.status).toUpperCase(),
                              ),
                              _MetaBadge(label: task.priority.toUpperCase()),
                              _MetaBadge(
                                label:
                                    'UPDATED ${formatShortDate(task.updatedAt)}',
                              ),
                              if (task.reminderAt != null)
                                _MetaBadge(
                                  label:
                                      'REMINDER ${formatShortDateTime(task.reminderAt)}',
                                ),
                            ],
                          ),
                          if (_memberUiReadOnly) ...[
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Admin inspection keeps this member task view read-only. Use the Admin Console for task, file, and reminder writes.',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                          if (_canManageContent) ...[
                            const SizedBox(height: AppSpacing.md),
                            ResponsiveActionGroup(
                              children: [
                                MechaButton(
                                  label: 'EDIT TASK',
                                  variant: MechaButtonVariant.outlined,
                                  onTap: _busyId == task.id
                                      ? null
                                      : _showTaskEditDialog,
                                ),
                                MechaButton(
                                  label: 'DELETE TASK',
                                  variant: MechaButtonVariant.outlined,
                                  onTap:
                                      _busyId == task.id ? null : _deleteTask,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    MechaPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final attachButton = !_canManageContent
                                  ? null
                                  : TextButton(
                                      onPressed: _busyId == task.id
                                          ? null
                                          : _showAttachFilesDialog,
                                      child: Text(
                                        'ATTACH FILES',
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    );

                              if (constraints.maxWidth < 520) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tags & Attachments',
                                      style: AppTextStyles.titleMedium,
                                    ),
                                    if (attachButton != null) attachButton,
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Tags & Attachments',
                                      style: AppTextStyles.titleMedium,
                                    ),
                                  ),
                                  if (attachButton != null) attachButton,
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          if (task.tags.isEmpty)
                            Text(
                              'No tags assigned.',
                              style: AppTextStyles.bodySmall,
                            )
                          else
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: task.tags
                                  .map(
                                    (tag) => _TagChip(
                                      label: tag.name,
                                      colorHex: tag.color,
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                          const SizedBox(height: AppSpacing.md),
                          if (task.files.isEmpty)
                            Text(
                              'No files attached.',
                              style: AppTextStyles.bodySmall,
                            )
                          else
                            Column(
                              children: task.files
                                  .map(
                                    (file) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: AppSpacing.sm,
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.insert_drive_file_outlined,
                                            color: AppColors.primary,
                                          ),
                                          const SizedBox(width: AppSpacing.sm),
                                          Expanded(
                                            child: Text(
                                              '${file.originalName} · ${file.kind.toUpperCase()}',
                                              style: AppTextStyles.bodyMedium,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    MechaPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Comment Thread',
                              style: AppTextStyles.titleMedium),
                          const SizedBox(height: AppSpacing.md),
                          if (_canComment) ...[
                            TextField(
                              controller: _commentController,
                              minLines: 3,
                              maxLines: 5,
                              style: AppTextStyles.bodyMedium,
                              decoration: const InputDecoration(
                                hintText: 'Drop an update or handoff note',
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            MechaButton(
                              label: _submittingComment
                                  ? 'SENDING...'
                                  : 'ADD COMMENT',
                              onTap: _submittingComment ? null : _submitComment,
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ] else ...[
                            Text(
                              'Comments are disabled in read-only admin inspection mode.',
                              style: AppTextStyles.bodySmall,
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                          if (_comments.isEmpty)
                            const WorkspaceEmptyState(
                              icon: Icons.chat_bubble_outline,
                              title: 'No Comments Yet',
                              message:
                                  'Start the thread here for project discussion and task-level updates.',
                            )
                          else
                            Column(
                              children: _comments
                                  .map(
                                    (comment) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: AppSpacing.md,
                                      ),
                                      child: MechaPanel(
                                        padding: const EdgeInsets.all(
                                          AppSpacing.md,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    comment.author
                                                            ?.resolvedDisplayName ??
                                                        comment.authorId,
                                                    style: AppTextStyles
                                                        .titleMedium,
                                                  ),
                                                ),
                                                Text(
                                                  formatShortDateTime(
                                                    comment.createdAt,
                                                  ),
                                                  style: AppTextStyles.caption,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(
                                                height: AppSpacing.sm),
                                            Text(
                                              comment.content,
                                              style: AppTextStyles.bodyMedium,
                                            ),
                                            if (_canManageComment(comment)) ...[
                                              const SizedBox(
                                                height: AppSpacing.sm,
                                              ),
                                              Row(
                                                children: [
                                                  TextButton(
                                                    onPressed: _busyId ==
                                                            comment.id
                                                        ? null
                                                        : () =>
                                                            _showCommentEditDialog(
                                                              comment,
                                                            ),
                                                    child: Text(
                                                      'EDIT',
                                                      style: AppTextStyles
                                                          .caption
                                                          .copyWith(
                                                        color:
                                                            AppColors.primary,
                                                      ),
                                                    ),
                                                  ),
                                                  TextButton(
                                                    onPressed: _busyId ==
                                                            comment.id
                                                        ? null
                                                        : () => _deleteComment(
                                                              comment,
                                                            ),
                                                    child: const Text(
                                                      'DELETE',
                                                      style: TextStyle(
                                                        color: Colors.redAccent,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

Color _parseColor(String rawColor) {
  final normalized = rawColor.replaceAll('#', '');
  final hex = normalized.length == 6 ? 'FF$normalized' : normalized;
  return Color(int.tryParse(hex, radix: 16) ?? 0xFF7DD3FC);
}

class _MetaBadge extends StatelessWidget {
  const _MetaBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Text(label, style: AppTextStyles.caption),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.colorHex,
  });

  final String label;
  final String colorHex;

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(colorHex);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.52)),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.caption.copyWith(color: color),
      ),
    );
  }
}
