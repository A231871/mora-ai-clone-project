import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/services/api_client.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/workspace_models.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/expandable_filter_panel.dart';
import '../../../shared/widgets/mecha_button.dart';
import '../../../shared/widgets/mecha_panel.dart';
import '../../../shared/widgets/workspace_empty_state.dart';
import '../../../shared/widgets/workspace_screen_shell.dart';
import '../../auth/services/session_storage.dart';
import '../services/projects_service.dart';

class ProjectsListScreen extends StatefulWidget {
  const ProjectsListScreen({super.key});

  @override
  State<ProjectsListScreen> createState() => _ProjectsListScreenState();
}

class _ProjectsListScreenState extends State<ProjectsListScreen> {
  final ProjectsService _projectsService = ProjectsService();
  final TextEditingController _searchController = TextEditingController();

  List<WorkspaceProject> _projects = const <WorkspaceProject>[];
  AppUser? _currentUser;
  bool _loading = true;
  String? _busyProjectId;
  bool _filtersExpanded = false;
  String _roleFilter = 'all';
  String _sortMode = 'recent';

  bool get _canCreateProjects => _currentUser != null;

  List<WorkspaceProject> get _visibleProjects {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = _projects.where((project) {
      final matchesSearch = query.isEmpty ||
          project.name.toLowerCase().contains(query) ||
          project.description.toLowerCase().contains(query) ||
          (project.createdByUser?.resolvedDisplayName
                  .toLowerCase()
                  .contains(query) ??
              false);

      final matchesRole =
          _roleFilter == 'all' || _projectRoleKey(project) == _roleFilter;

      return matchesSearch && matchesRole;
    }).toList(growable: false);

    filtered.sort((a, b) {
      switch (_sortMode) {
        case 'role_desc':
          final roleCompare =
              _projectRoleWeight(b).compareTo(_projectRoleWeight(a));
          return roleCompare != 0 ? roleCompare : _compareByDateDesc(a, b);
        case 'role_asc':
          final roleCompare =
              _projectRoleWeight(a).compareTo(_projectRoleWeight(b));
          return roleCompare != 0 ? roleCompare : _compareByDateDesc(a, b);
        case 'name':
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case 'recent':
        default:
          return _compareByDateDesc(a, b);
      }
    });

    return filtered;
  }

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait<dynamic>([
        _projectsService.listProjects(),
        SessionStorage.getCurrentUser(),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _projects = results[0] as List<WorkspaceProject>;
        _currentUser = results[1] as AppUser?;
        _loading = false;
        _busyProjectId = null;
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
      _showMessage('Failed to load projects: $error');
    }
  }

  Future<void> _showProjectDialog({WorkspaceProject? project}) async {
    final nameController = TextEditingController(text: project?.name ?? '');
    final descriptionController =
        TextEditingController(text: project?.description ?? '');
    var visibility = project?.visibility ?? 'private';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          title: Text(
            project == null ? 'Create Project' : 'Update Project',
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
                  decoration: const InputDecoration(
                    hintText: 'Project name',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: descriptionController,
                  minLines: 3,
                  maxLines: 5,
                  style: AppTextStyles.bodyMedium,
                  decoration: const InputDecoration(
                    hintText: 'Mission summary',
                  ),
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
              child: Text(
                project == null ? 'CREATE' : 'SAVE',
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
      _showMessage('Project name is required.');
      return;
    }

    setState(() => _busyProjectId = project?.id ?? 'creating');
    try {
      if (project == null) {
        await _projectsService.createProject(
          name: nameController.text.trim(),
          description: descriptionController.text.trim(),
          visibility: visibility,
        );
        _showMessage('Project created.', isError: false);
      } else {
        await _projectsService.updateProject(
          project.id,
          name: nameController.text.trim(),
          description: descriptionController.text.trim(),
          visibility: visibility,
        );
        _showMessage('Project updated.', isError: false);
      }
      if (!mounted) {
        return;
      }
      await _loadProjects();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _busyProjectId = null);
      _showMessage(error.message);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _busyProjectId = null);
      _showMessage('Project save failed: $error');
    }
  }

  Future<void> _deleteProject(WorkspaceProject project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title:
            Text('Delete ${project.name}?', style: AppTextStyles.titleMedium),
        content: Text(
          'This removes related tasks, members, tags, reminders, and project files.',
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

    setState(() => _busyProjectId = project.id);
    try {
      await _projectsService.deleteProject(project.id);
      if (!mounted) {
        return;
      }
      _showMessage('Project deleted.', isError: false);
      await _loadProjects();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _busyProjectId = null);
      _showMessage(error.message);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _busyProjectId = null);
      _showMessage('Delete failed: $error');
    }
  }

  int _compareByDateDesc(WorkspaceProject a, WorkspaceProject b) {
    final aDate = a.updatedAt ?? a.createdAt ?? DateTime(2000);
    final bDate = b.updatedAt ?? b.createdAt ?? DateTime(2000);
    return bDate.compareTo(aDate);
  }

  int _projectRoleWeight(WorkspaceProject project) {
    return switch (project.currentRole) {
      'owner' => 3,
      'editor' => 2,
      'viewer' => 1,
      _ => 0,
    };
  }

  String _projectRoleKey(WorkspaceProject project) {
    return project.currentRole ?? 'unknown';
  }

  String _sortLabel(String sortMode) {
    return switch (sortMode) {
      'recent' => 'recent activity',
      'role_desc' => 'role high to low',
      'role_asc' => 'role low to high',
      'name' => 'name',
      _ => sortMode,
    };
  }

  String get _projectFiltersSummary {
    final tokens = <String>[];
    final query = _searchController.text.trim();

    if (query.isNotEmpty) {
      tokens.add('Search "$query"');
    }
    if (_roleFilter != 'all') {
      tokens.add('Role ${titleCaseToken(_roleFilter)}');
    }
    if (_sortMode != 'recent') {
      tokens.add('Sort ${titleCaseToken(_sortLabel(_sortMode))}');
    }

    return tokens.isEmpty
        ? 'Tap to search and sort accepted projects.'
        : tokens.join(' · ');
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
    return WorkspaceScreenShell(
      title: 'Projects',
      trailing: IconButton(
        onPressed: _loading ? null : _loadProjects,
        icon: const Icon(Icons.refresh, color: AppColors.primary),
      ),
      floatingActionButton: _canCreateProjects
          ? FloatingActionButton(
              onPressed: () => _showProjectDialog(),
              child: const Icon(Icons.add),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Browse accepted projects, filter by role, and sort by access level or recent activity.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          ExpandableFilterPanel(
            title: 'Search & Filters',
            summary: _projectFiltersSummary,
            expanded: _filtersExpanded,
            onExpandedChanged: (expanded) =>
                setState(() => _filtersExpanded = expanded),
            collapsedHint: 'Tap to search, filter, and sort accepted projects.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: AppTextStyles.bodyMedium,
                  decoration: const InputDecoration(
                    hintText: 'Search project name, description, or creator',
                    prefixIcon: Icon(Icons.search, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final option in const <(String, String)>[
                      ('all', 'ALL'),
                      ('owner', 'OWNER'),
                      ('editor', 'EDITOR'),
                      ('viewer', 'VIEWER'),
                    ])
                      ChoiceChip(
                        label: Text(option.$2),
                        selected: _roleFilter == option.$1,
                        onSelected: (_) =>
                            setState(() => _roleFilter = option.$1),
                        selectedColor: AppColors.primary.withValues(alpha: 0.3),
                        backgroundColor: AppColors.bgCard,
                        side: BorderSide(
                          color: _roleFilter == option.$1
                              ? AppColors.primary
                              : AppColors.textSecondary.withValues(alpha: 0.35),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: _sortMode,
                  dropdownColor: AppColors.bgCard,
                  decoration: const InputDecoration(labelText: 'Sort'),
                  items: const [
                    DropdownMenuItem(
                        value: 'recent', child: Text('RECENT ACTIVITY')),
                    DropdownMenuItem(
                        value: 'role_desc', child: Text('ROLE: HIGH TO LOW')),
                    DropdownMenuItem(
                        value: 'role_asc', child: Text('ROLE: LOW TO HIGH')),
                    DropdownMenuItem(value: 'name', child: Text('NAME')),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() => _sortMode = value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _visibleProjects.isEmpty
                    ? Center(
                        child: WorkspaceEmptyState(
                          icon: Icons.dashboard_customize_outlined,
                          title: 'No Matching Projects',
                          message: _projects.isEmpty
                              ? 'Accepted projects will appear here after you create one or accept an invitation in Profile / Inbox.'
                              : 'Try a different search, role filter, or sort mode.',
                          actionLabel:
                              _canCreateProjects ? 'Create Project' : null,
                          onAction: _canCreateProjects
                              ? () => _showProjectDialog()
                              : null,
                        ),
                      )
                    : ListView.separated(
                        itemCount: _visibleProjects.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final project = _visibleProjects[index];
                          final isBusy = _busyProjectId == project.id;
                          final canManageMetadata =
                              project.canEditProjectMetadata;

                          return MechaPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            project.name,
                                            style: AppTextStyles.titleLarge,
                                          ),
                                          const SizedBox(height: AppSpacing.xs),
                                          Text(
                                            project.description.isEmpty
                                                ? 'No description yet.'
                                                : project.description,
                                            style: AppTextStyles.bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                    _ProjectBadge(
                                      label: project.visibility,
                                      color: project.isShared
                                          ? AppColors.statusGreen
                                          : AppColors.primary,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Wrap(
                                  spacing: AppSpacing.sm,
                                  runSpacing: AppSpacing.sm,
                                  children: [
                                    if (project.currentRole != null)
                                      _ProjectBadge(
                                        label: project.currentRole!,
                                        color: AppColors.accent,
                                      ),
                                    if (project.ownerUsers.isNotEmpty)
                                      _ProjectBadge(
                                        label:
                                            'owners ${project.ownerUsers.length}',
                                        color: AppColors.textSecondary,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'Updated ${formatShortDateTime(project.updatedAt)}'
                                  '${project.createdByUser != null ? ' · creator ${project.createdByUser!.resolvedDisplayName}' : ''}',
                                  style: AppTextStyles.caption,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final actions = <Widget>[
                                      MechaButton(
                                        label: 'OPEN WORKSPACE',
                                        onTap: () async {
                                          final result = await context.push(
                                            '/projects/${project.id}',
                                          );
                                          if (result == true) {
                                            _loadProjects();
                                          }
                                        },
                                      ),
                                      if (canManageMetadata)
                                        MechaButton(
                                          label: 'EDIT',
                                          variant: MechaButtonVariant.outlined,
                                          onTap: isBusy
                                              ? null
                                              : () => _showProjectDialog(
                                                    project: project,
                                                  ),
                                        ),
                                      if (canManageMetadata)
                                        MechaButton(
                                          label: isBusy ? '...' : 'DELETE',
                                          variant: MechaButtonVariant.outlined,
                                          onTap: isBusy
                                              ? null
                                              : () => _deleteProject(project),
                                        ),
                                    ];

                                    if (constraints.maxWidth < 540) {
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          for (var i = 0;
                                              i < actions.length;
                                              i++) ...[
                                            actions[i],
                                            if (i < actions.length - 1)
                                              const SizedBox(
                                                  height: AppSpacing.sm),
                                          ],
                                        ],
                                      );
                                    }

                                    return Row(
                                      children: [
                                        for (var i = 0;
                                            i < actions.length;
                                            i++) ...[
                                          Expanded(child: actions[i]),
                                          if (i < actions.length - 1)
                                            const SizedBox(
                                                width: AppSpacing.sm),
                                        ],
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _ProjectBadge extends StatelessWidget {
  const _ProjectBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        titleCaseToken(label).toUpperCase(),
        style: AppTextStyles.caption.copyWith(color: color),
      ),
    );
  }
}
