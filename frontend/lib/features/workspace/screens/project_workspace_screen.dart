import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/services/api_client.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/workspace_models.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/kpi_chip.dart';
import '../../../shared/widgets/mecha_button.dart';
import '../../../shared/widgets/mecha_panel.dart';
import '../../../shared/widgets/responsive_action_group.dart';
import '../../../shared/widgets/segmented_tab_bar.dart';
import '../../../shared/widgets/workspace_empty_state.dart';
import '../../../shared/widgets/workspace_screen_shell.dart';
import '../services/files_service.dart';
import '../services/projects_service.dart';
import '../services/tasks_service.dart';

class ProjectWorkspaceScreen extends StatefulWidget {
  const ProjectWorkspaceScreen({
    super.key,
    required this.projectId,
  });

  final String projectId;

  @override
  State<ProjectWorkspaceScreen> createState() => _ProjectWorkspaceScreenState();
}

class _ProjectWorkspaceScreenState extends State<ProjectWorkspaceScreen> {
  final ProjectsService _projectsService = ProjectsService();
  final TasksService _tasksService = TasksService();
  final FilesService _filesService = FilesService();

  WorkspaceProject? _project;
  List<ProjectTag> _tags = const <ProjectTag>[];
  List<ProjectMember> _members = const <ProjectMember>[];
  List<ProjectInvite> _pendingInvites = const <ProjectInvite>[];
  List<TaskItem> _tasks = const <TaskItem>[];
  bool _loading = true;
  String? _busyId;
  int _selectedTab = 0;
  String _statusFilter = 'all';
  String _priorityFilter = 'all';

  bool get _canEditProjectMetadata => _project?.canEditProjectMetadata ?? false;
  bool get _canManageMembers => _project?.canManageMembers ?? false;
  bool get _canManageContent => _project?.canManageContent ?? false;
  bool get _memberUiReadOnly => _project?.memberUiReadOnly ?? false;
  List<ProjectMember> get _assignableMembers =>
      _members.where((member) => member.user != null).toList(growable: false);

  List<TaskItem> get _visibleTasks {
    return _tasks.where((task) {
      final statusMatches =
          _statusFilter == 'all' || task.status == _statusFilter;
      final priorityMatches =
          _priorityFilter == 'all' || task.priority == _priorityFilter;
      return statusMatches && priorityMatches;
    }).toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _loadWorkspace();
  }

  Future<void> _loadWorkspace() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait<dynamic>([
        _projectsService.getProject(widget.projectId),
        _projectsService.listTags(widget.projectId),
        _projectsService.listMembers(widget.projectId),
        _tasksService.listTasks(projectId: widget.projectId),
      ]);
      final project = results[0] as WorkspaceProject;
      List<ProjectInvite> pendingInvites = const <ProjectInvite>[];
      if (project.canManageMembers) {
        try {
          pendingInvites = (await _projectsService.listProjectInvites(
            widget.projectId,
          ))
              .where((invite) => invite.isPending)
              .toList(growable: false);
        } catch (_) {
          pendingInvites = const <ProjectInvite>[];
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _project = project;
        _tags = results[1] as List<ProjectTag>;
        _members = results[2] as List<ProjectMember>;
        _pendingInvites = pendingInvites;
        _tasks = results[3] as List<TaskItem>;
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
      _showMessage('Failed to load project workspace: $error');
    }
  }

  Future<void> _showProjectEditDialog() async {
    final project = _project;
    if (project == null) {
      return;
    }

    final nameController = TextEditingController(text: project.name);
    final descriptionController =
        TextEditingController(text: project.description);
    var visibility = project.visibility;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          title: Text('Update Project', style: AppTextStyles.titleMedium),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: AppTextStyles.bodyMedium,
                  decoration: const InputDecoration(hintText: 'Project name'),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: descriptionController,
                  minLines: 3,
                  maxLines: 5,
                  style: AppTextStyles.bodyMedium,
                  decoration:
                      const InputDecoration(hintText: 'Mission summary'),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: visibility,
                  dropdownColor: AppColors.bgCard,
                  items: const [
                    DropdownMenuItem(
                      value: 'private',
                      child: Text('PRIVATE'),
                    ),
                    DropdownMenuItem(
                      value: 'shared',
                      child: Text('SHARED'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => visibility = value);
                    }
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

    setState(() => _busyId = project.id);
    try {
      await _projectsService.updateProject(
        project.id,
        name: nameController.text.trim(),
        description: descriptionController.text.trim(),
        visibility: visibility,
      );
      if (!mounted) {
        return;
      }
      _showMessage('Project updated.', isError: false);
      await _loadWorkspace();
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
      _showMessage('Update failed: $error');
    }
  }

  Future<void> _deleteProject() async {
    final project = _project;
    if (project == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title:
            Text('Delete ${project.name}?', style: AppTextStyles.titleMedium),
        content: Text(
          'This permanently removes the full workspace tree for this project.',
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
              'DELETE',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() => _busyId = project.id);
    try {
      await _projectsService.deleteProject(project.id);
      if (!mounted) {
        return;
      }
      context.pop(true);
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

  Future<void> _showTaskDialog({TaskItem? task}) async {
    final project = _project;
    if (project == null) {
      return;
    }

    final nameController = TextEditingController(text: task?.title ?? '');
    final descriptionController =
        TextEditingController(text: task?.description ?? '');
    var status = task?.status ?? 'todo';
    var priority = task?.priority ?? 'medium';
    var reminderAt = task?.reminderAt;
    final selectedAssigneeIds = <String>{
      ...task?.assigneeIds ?? const <String>[]
    };
    final selectedTagIds = <String>{...task?.tagIds ?? const <String>[]};
    final selectedFileIds = <String>{...task?.fileIds ?? const <String>[]};

    List<FileAsset> availableFiles = const <FileAsset>[];
    try {
      availableFiles = await _filesService.listFiles(ownerType: 'unassigned');
    } catch (_) {
      availableFiles = const <FileAsset>[];
    }

    if (!mounted) {
      return;
    }

    final fileOptions = <FileAsset>[
      ...?task?.files,
      ...availableFiles.where((file) => !selectedFileIds.contains(file.id)),
    ];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          title: Text(
            task == null ? 'Create Task' : 'Update Task',
            style: AppTextStyles.titleMedium,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
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
                if (_assignableMembers.isEmpty)
                  Text(
                    'No accepted project members are available for assignment yet.',
                    style: AppTextStyles.bodySmall,
                  )
                else
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final member in _assignableMembers)
                        FilterChip(
                          label: Text(
                            member.user?.resolvedDisplayName ??
                                member.user?.username ??
                                member.userId,
                          ),
                          selected: selectedAssigneeIds.contains(member.userId),
                          selectedColor:
                              AppColors.primary.withValues(alpha: 0.22),
                          backgroundColor: AppColors.bgDeep,
                          side: BorderSide(
                            color: selectedAssigneeIds.contains(member.userId)
                                ? AppColors.primary
                                : AppColors.textSecondary
                                    .withValues(alpha: 0.25),
                          ),
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
                    ],
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
                        side: BorderSide(
                          color: selectedTagIds.contains(tag.id)
                              ? AppColors.primary
                              : AppColors.textSecondary.withValues(alpha: 0.25),
                        ),
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
                const SizedBox(height: AppSpacing.md),
                Text('Attach From Vault', style: AppTextStyles.caption),
                const SizedBox(height: AppSpacing.xs),
                if (fileOptions.isEmpty)
                  Text(
                    'No unassigned files available. Upload in Files Vault first.',
                    style: AppTextStyles.bodySmall,
                  )
                else
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final file in fileOptions)
                        FilterChip(
                          label: SizedBox(
                            width: 160,
                            child: Text(
                              file.originalName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          selected: selectedFileIds.contains(file.id),
                          selectedColor:
                              AppColors.primary.withValues(alpha: 0.22),
                          backgroundColor: AppColors.bgDeep,
                          onSelected: (selected) {
                            setDialogState(() {
                              if (selected) {
                                selectedFileIds.add(file.id);
                              } else {
                                selectedFileIds.remove(file.id);
                              }
                            });
                          },
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
              child: Text(
                task == null ? 'CREATE' : 'SAVE',
                style: const TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) {
      return;
    }

    if (nameController.text.trim().isEmpty) {
      _showMessage('Task title is required.');
      return;
    }

    setState(() => _busyId = task?.id ?? 'task-create');
    try {
      if (task == null) {
        await _tasksService.createTask(
          projectId: project.id,
          title: nameController.text.trim(),
          description: descriptionController.text.trim(),
          status: status,
          priority: priority,
          assigneeIds: selectedAssigneeIds.toList(growable: false),
          tagIds: selectedTagIds.toList(growable: false),
          fileIds: selectedFileIds.toList(growable: false),
          reminderAt: reminderAt,
        );
        _showMessage('Task created.', isError: false);
      } else {
        await _tasksService.updateTask(
          task.id,
          title: nameController.text.trim(),
          description: descriptionController.text.trim(),
          status: status,
          priority: priority,
          assigneeIds: selectedAssigneeIds.toList(growable: false),
          tagIds: selectedTagIds.toList(growable: false),
          fileIds: selectedFileIds.toList(growable: false),
          reminderAt: reminderAt,
          clearReminder: reminderAt == null && task.reminderAt != null,
        );
        _showMessage('Task updated.', isError: false);
      }
      if (!mounted) {
        return;
      }
      await _loadWorkspace();
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
      _showMessage('Task save failed: $error');
    }
  }

  Future<void> _deleteTask(TaskItem task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: Text('Delete ${task.title}?', style: AppTextStyles.titleMedium),
        content: Text(
          'This also removes task comments, linked reminder records, and attached task files.',
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
              'DELETE',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() => _busyId = task.id);
    try {
      await _tasksService.deleteTask(task.id);
      if (!mounted) {
        return;
      }
      _showMessage('Task deleted.', isError: false);
      await _loadWorkspace();
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

  Future<void> _showTagDialog({ProjectTag? tag}) async {
    final controller = TextEditingController(text: tag?.name ?? '');
    final colorController =
        TextEditingController(text: tag?.color ?? '#7dd3fc');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: Text(
          tag == null ? 'Create Tag' : 'Update Tag',
          style: AppTextStyles.titleMedium,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              style: AppTextStyles.bodyMedium,
              decoration: const InputDecoration(hintText: 'Tag name'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: colorController,
              style: AppTextStyles.bodyMedium,
              decoration: const InputDecoration(hintText: '#38bdf8'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              tag == null ? 'CREATE' : 'SAVE',
              style: const TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() => _busyId = tag?.id ?? 'tag-create');
    try {
      if (tag == null) {
        await _projectsService.createTag(
          widget.projectId,
          name: controller.text.trim(),
          color: colorController.text.trim(),
        );
        _showMessage('Tag created.', isError: false);
      } else {
        await _projectsService.updateTag(
          widget.projectId,
          tag.id,
          name: controller.text.trim(),
          color: colorController.text.trim(),
        );
        _showMessage('Tag updated.', isError: false);
      }

      if (!mounted) {
        return;
      }
      await _loadWorkspace();
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
      _showMessage('Tag save failed: $error');
    }
  }

  Future<void> _deleteTag(ProjectTag tag) async {
    setState(() => _busyId = tag.id);
    try {
      await _projectsService.deleteTag(widget.projectId, tag.id);
      if (!mounted) {
        return;
      }
      _showMessage('Tag removed.', isError: false);
      await _loadWorkspace();
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
      _showMessage('Tag delete failed: $error');
    }
  }

  Future<void> _showMemberDialog({ProjectMember? member}) async {
    var role = member?.role ?? 'viewer';
    final controller = TextEditingController(
      text: member?.user?.username ?? member?.userId ?? '',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          title: Text(
            member == null ? 'Invite Member' : 'Update Member',
            style: AppTextStyles.titleMedium,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (member == null) ...[
                  TextField(
                    controller: controller,
                    style: AppTextStyles.bodyMedium,
                    decoration: const InputDecoration(
                      hintText: 'Username',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Send a pending invitation by username. Accepted users become project members and can be assigned to tasks.',
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                DropdownButtonFormField<String>(
                  initialValue: role,
                  dropdownColor: AppColors.bgCard,
                  items: const [
                    DropdownMenuItem(value: 'viewer', child: Text('VIEWER')),
                    DropdownMenuItem(value: 'editor', child: Text('EDITOR')),
                    DropdownMenuItem(value: 'owner', child: Text('OWNER')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => role = value);
                    }
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
              child: Text(
                member == null ? 'INVITE' : 'SAVE',
                style: const TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() => _busyId = member?.id ?? 'member-create');
    try {
      if (member == null) {
        if (controller.text.trim().isEmpty) {
          throw const ApiException(400, 'Username is required');
        }
        await _projectsService.createInvite(
          widget.projectId,
          username: controller.text.trim(),
          role: role,
        );
        _showMessage('Invitation sent.', isError: false);
      } else {
        await _projectsService.updateMember(
          widget.projectId,
          member.id,
          role: role,
        );
        _showMessage('Member updated.', isError: false);
      }
      if (!mounted) {
        return;
      }
      await _loadWorkspace();
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
      _showMessage('Member save failed: $error');
    }
  }

  Future<void> _deleteMember(ProjectMember member) async {
    setState(() => _busyId = member.id);
    try {
      await _projectsService.deleteMember(widget.projectId, member.id);
      if (!mounted) {
        return;
      }
      _showMessage('Member removed.', isError: false);
      await _loadWorkspace();
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
      _showMessage('Member removal failed: $error');
    }
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
    final project = _project;

    return WorkspaceScreenShell(
      title: project?.name ?? 'Project Workspace',
      trailing: IconButton(
        onPressed: _loading ? null : _loadWorkspace,
        icon: const Icon(Icons.refresh, color: AppColors.primary),
      ),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : project == null
              ? const Center(
                  child: WorkspaceEmptyState(
                    icon: Icons.error_outline,
                    title: 'Project Missing',
                    message: 'The requested workspace could not be loaded.',
                  ),
                )
              : ListView(
                  children: [
                    MechaPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      project.name,
                                      style: AppTextStyles.displayMedium
                                          .copyWith(fontSize: 26),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      project.description.isEmpty
                                          ? 'No project briefing yet.'
                                          : project.description,
                                      style: AppTextStyles.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              if (project.currentRole != null)
                                _MetaBadge(
                                  label: titleCaseToken(project.currentRole!)
                                      .toUpperCase(),
                                ),
                              if (_memberUiReadOnly) ...[
                                const SizedBox(width: AppSpacing.sm),
                                const _MetaBadge(label: 'READ ONLY'),
                              ],
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              KpiChip(
                                  label: 'Tasks', value: '${_tasks.length}'),
                              KpiChip(label: 'Tags', value: '${_tags.length}'),
                              KpiChip(
                                label: 'Members',
                                value: '${_members.length}',
                              ),
                              if (_canManageMembers)
                                KpiChip(
                                  label: 'Pending Invites',
                                  value: '${_pendingInvites.length}',
                                ),
                              KpiChip(
                                label: 'Visibility',
                                value: project.visibility.toUpperCase(),
                              ),
                            ],
                          ),
                          if (_memberUiReadOnly) ...[
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Admin inspection keeps this member workspace read-only. Use the Admin Console for project, task, tag, file, and reminder writes.',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                          if (_canEditProjectMetadata) ...[
                            const SizedBox(height: AppSpacing.md),
                            ResponsiveActionGroup(
                              children: [
                                MechaButton(
                                  label: 'EDIT PROJECT',
                                  variant: MechaButtonVariant.outlined,
                                  onTap: _busyId == project.id
                                      ? null
                                      : _showProjectEditDialog,
                                ),
                                if (project.canManageMembers)
                                  MechaButton(
                                    label: 'DELETE PROJECT',
                                    variant: MechaButtonVariant.outlined,
                                    onTap: _busyId == project.id
                                        ? null
                                        : _deleteProject,
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SegmentedTabBar(
                      tabs: const ['Overview', 'Tasks', 'Tags', 'Members'],
                      selectedIndex: _selectedTab,
                      onSelected: (index) {
                        setState(() => _selectedTab = index);
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildTabContent(project),
                  ],
                ),
    );
  }

  Widget _buildTabContent(WorkspaceProject project) {
    switch (_selectedTab) {
      case 0:
        final completedTasks =
            _tasks.where((task) => task.status == 'done').length;
        return Column(
          children: [
            MechaPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Command Overview', style: AppTextStyles.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _memberUiReadOnly
                        ? 'This workspace is open for inspection only. Accepted members still keep their normal task and tag flows, but admin override access stays read-only here.'
                        : 'This workspace keeps task operations, tag structure, file attachment flow, and member roles under the same project scope.',
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      KpiChip(
                        label: 'Completed',
                        value: '$completedTasks/${_tasks.length}',
                      ),
                      KpiChip(
                        label: 'In Progress',
                        value:
                            '${_tasks.where((task) => task.status == 'in_progress').length}',
                      ),
                      KpiChip(
                        label: 'Owners',
                        value:
                            '${_members.where((member) => member.role == 'owner').length}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            MechaPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Default Tags', style: AppTextStyles.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  if (_tags.isEmpty)
                    Text(
                      'No tags configured yet.',
                      style: AppTextStyles.bodySmall,
                    )
                  else
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: _tags
                          .map(
                            (tag) => _ColorTagChip(
                              label: tag.name,
                              colorHex: tag.color,
                            ),
                          )
                          .toList(growable: false),
                    ),
                ],
              ),
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_canManageContent)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: MechaButton(
                  label: 'CREATE TASK',
                  onTap: () => _showTaskDialog(),
                ),
              ),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final status in const [
                  'all',
                  'todo',
                  'in_progress',
                  'done'
                ])
                  ChoiceChip(
                    label: Text(titleCaseToken(status).toUpperCase()),
                    selected: _statusFilter == status,
                    onSelected: (_) => setState(() => _statusFilter = status),
                    selectedColor: AppColors.primary.withValues(alpha: 0.3),
                    backgroundColor: AppColors.bgCard,
                  ),
                for (final priority in const ['all', 'low', 'medium', 'high'])
                  ChoiceChip(
                    label: Text(priority.toUpperCase()),
                    selected: _priorityFilter == priority,
                    onSelected: (_) =>
                        setState(() => _priorityFilter = priority),
                    selectedColor: AppColors.accent.withValues(alpha: 0.3),
                    backgroundColor: AppColors.bgCard,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (_visibleTasks.isEmpty)
              const WorkspaceEmptyState(
                icon: Icons.assignment_outlined,
                title: 'No Tasks Match',
                message:
                    'Adjust the filters or create a new task for this project.',
              )
            else
              Column(
                children: _visibleTasks
                    .map(
                      (task) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _TaskCard(
                          task: task,
                          busy: _busyId == task.id,
                          canEdit: _canManageContent,
                          onOpen: () async {
                            final result = await context.push(
                              '/projects/${project.id}/tasks/${task.id}',
                            );
                            if (result == true) {
                              _loadWorkspace();
                            }
                          },
                          onEdit: () => _showTaskDialog(task: task),
                          onDelete: () => _deleteTask(task),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
          ],
        );
      case 2:
        return Column(
          children: [
            if (_canManageContent)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: MechaButton(
                  label: 'CREATE TAG',
                  onTap: () => _showTagDialog(),
                ),
              ),
            if (_tags.isEmpty)
              const WorkspaceEmptyState(
                icon: Icons.sell_outlined,
                title: 'No Tags Yet',
                message:
                    'Tags help tasks stay filterable by workflow lane or priority theme.',
              )
            else
              Column(
                children: _tags
                    .map(
                      (tag) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: MechaPanel(
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: _parseColor(tag.color),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  '${tag.name} · ${tag.color}',
                                  style: AppTextStyles.bodyMedium,
                                ),
                              ),
                              if (_canManageContent) ...[
                                IconButton(
                                  onPressed: _busyId == tag.id
                                      ? null
                                      : () => _showTagDialog(tag: tag),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  onPressed: _busyId == tag.id
                                      ? null
                                      : () => _deleteTag(tag),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.redAccent,
                                  ),
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
        );
      case 3:
        return Column(
          children: [
            if (_canManageMembers)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: MechaButton(
                  label: 'INVITE MEMBER',
                  onTap: () => _showMemberDialog(),
                ),
              ),
            if (_members.isEmpty && _pendingInvites.isEmpty)
              const WorkspaceEmptyState(
                icon: Icons.group_outlined,
                title: 'No Collaborators Yet',
                message:
                    'Send a username invite to start building this workspace team.',
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Accepted Members', style: AppTextStyles.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  if (_members.isEmpty)
                    Text(
                      'No accepted members yet.',
                      style: AppTextStyles.bodySmall,
                    )
                  else
                    Column(
                      children: _members
                          .map(
                            (member) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.md,
                              ),
                              child: MechaPanel(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                member.user
                                                        ?.resolvedDisplayName ??
                                                    member.userId,
                                                style:
                                                    AppTextStyles.titleMedium,
                                              ),
                                              const SizedBox(
                                                height: AppSpacing.xs,
                                              ),
                                              Text(
                                                member.user?.email ??
                                                    member.user?.username ??
                                                    member.userId,
                                                style: AppTextStyles.bodySmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                        _MetaBadge(
                                          label: member.role.toUpperCase(),
                                        ),
                                      ],
                                    ),
                                    if (_canManageMembers) ...[
                                      const SizedBox(height: AppSpacing.md),
                                      ResponsiveActionGroup(
                                        breakpoint: 560,
                                        children: [
                                          MechaButton(
                                            label: 'CHANGE ROLE',
                                            variant:
                                                MechaButtonVariant.outlined,
                                            onTap: _busyId == member.id
                                                ? null
                                                : () => _showMemberDialog(
                                                      member: member,
                                                    ),
                                          ),
                                          MechaButton(
                                            label: 'REMOVE',
                                            variant:
                                                MechaButtonVariant.outlined,
                                            onTap: _busyId == member.id
                                                ? null
                                                : () => _deleteMember(member),
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
                  if (_canManageMembers) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Pending Invitations',
                      style: AppTextStyles.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (_pendingInvites.isEmpty)
                      Text(
                        'No pending invites right now.',
                        style: AppTextStyles.bodySmall,
                      )
                    else
                      Column(
                        children: _pendingInvites
                            .map(
                              (invite) => Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.md,
                                ),
                                child: MechaPanel(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        invite.invitee?.resolvedDisplayName ??
                                            invite.invitee?.username ??
                                            invite.inviteeUserId,
                                        style: AppTextStyles.titleMedium,
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        '@${invite.invitee?.username ?? invite.inviteeUserId} - ${titleCaseToken(invite.role)}',
                                        style: AppTextStyles.bodySmall,
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        'Invited ${formatShortDate(invite.createdAt)}',
                                        style: AppTextStyles.caption,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
                  ],
                ],
              ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

Color _parseColor(String rawColor) {
  final normalized = rawColor.replaceAll('#', '');
  final hex = normalized.length == 6 ? 'FF$normalized' : normalized;
  return Color(int.tryParse(hex, radix: 16) ?? 0xFF7DD3FC);
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.busy,
    required this.canEdit,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final TaskItem task;
  final bool busy;
  final bool canEdit;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return MechaPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(task.title, style: AppTextStyles.titleMedium),
              ),
              _MetaBadge(label: titleCaseToken(task.status).toUpperCase()),
              const SizedBox(width: AppSpacing.sm),
              _MetaBadge(label: task.priority.toUpperCase()),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            task.description.isEmpty
                ? 'No task description.'
                : task.description,
            style: AppTextStyles.bodySmall,
          ),
          if (task.assignees.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: task.assignees
                  .map(
                    (assignee) => _AssigneeChip(
                      label: assignee.resolvedDisplayName,
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (task.reminderAt != null)
                _MetaBadge(
                    label: 'REMINDER ${formatShortDate(task.reminderAt)}'),
              for (final tag in task.tags)
                _ColorTagChip(label: tag.name, colorHex: tag.color),
              if (task.files.isNotEmpty)
                _MetaBadge(label: '${task.files.length} FILES'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ResponsiveActionGroup(
            breakpoint: 720,
            children: [
              MechaButton(
                label: 'OPEN DETAIL',
                onTap: onOpen,
              ),
              if (canEdit)
                MechaButton(
                  label: 'EDIT',
                  variant: MechaButtonVariant.outlined,
                  onTap: busy ? null : onEdit,
                ),
              if (canEdit)
                MechaButton(
                  label: busy ? '...' : 'DELETE',
                  variant: MechaButtonVariant.outlined,
                  onTap: busy ? null : onDelete,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ColorTagChip extends StatelessWidget {
  const _ColorTagChip({
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

class _AssigneeChip extends StatelessWidget {
  const _AssigneeChip({required this.label});

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
          color: AppColors.accent.withValues(alpha: 0.28),
        ),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.caption.copyWith(color: AppColors.accent),
      ),
    );
  }
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
