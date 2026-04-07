import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/services/api_client.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/workspace_models.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/expandable_filter_panel.dart';
import '../../../shared/widgets/mecha_button.dart';
import '../../../shared/widgets/mecha_panel.dart';
import '../../../shared/widgets/mecha_text_field.dart';
import '../../../shared/widgets/responsive_action_group.dart';
import '../../../shared/widgets/segmented_tab_bar.dart';
import '../../../shared/widgets/workspace_empty_state.dart';
import '../../../shared/widgets/workspace_screen_shell.dart';
import '../../auth/services/session_storage.dart';
import '../services/admin_service.dart';

class AdminConsoleScreen extends StatefulWidget {
  const AdminConsoleScreen({super.key});

  @override
  State<AdminConsoleScreen> createState() => _AdminConsoleScreenState();
}

class _AdminConsoleScreenState extends State<AdminConsoleScreen> {
  final AdminService _adminService = AdminService();

  bool _loadingAccess = true;
  bool _forbidden = false;
  int _selectedTab = 0;

  List<AppUser> _userDirectory = const <AppUser>[];
  List<WorkspaceProject> _projectDirectory = const <WorkspaceProject>[];
  List<AppUser> _users = const <AppUser>[];
  List<WorkspaceProject> _projects = const <WorkspaceProject>[];
  List<TaskItem> _tasks = const <TaskItem>[];
  List<ProjectTag> _tags = const <ProjectTag>[];
  List<FileAsset> _files = const <FileAsset>[];
  List<ReminderEntry> _reminders = const <ReminderEntry>[];

  bool _loadingUsers = false;
  bool _loadingProjects = false;
  bool _loadingTasks = false;
  bool _loadingTags = false;
  bool _loadingFiles = false;
  bool _loadingReminders = false;
  String? _busyId;

  String _userQuery = '';
  String _userRole = 'all';
  String _userProvider = 'all';

  String _projectQuery = '';
  String _projectVisibility = 'all';
  String? _projectOwnerId;
  String? _projectCreatorId;

  String _taskQuery = '';
  String? _taskProjectId;
  String _taskStatus = 'all';
  String _taskPriority = 'all';
  String? _taskCreatorId;

  String _tagQuery = '';
  String? _tagProjectId;
  String? _tagCreatorId;

  String _fileQuery = '';
  String _fileKind = 'all';
  String _fileOwnerType = 'all';
  String? _fileUploaderId;

  String _reminderQuery = '';
  String? _reminderUserId;
  String _reminderCompleted = 'all';
  final Map<int, bool> _filterPanelsExpanded = <int, bool>{};

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() => _loadingAccess = true);
    final currentUser = await SessionStorage.getCurrentUser();
    if (!mounted) {
      return;
    }

    if (currentUser?.isAdmin != true) {
      setState(() {
        _forbidden = true;
        _loadingAccess = false;
      });
      return;
    }

    setState(() {
      _forbidden = false;
      _loadingAccess = false;
    });

    await _refreshDirectories();
    await _loadSelectedSection();
  }

  Future<void> _refreshDirectories() async {
    try {
      final results = await Future.wait<dynamic>([
        _adminService.listUsers(),
        _adminService.listProjects(),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _userDirectory = results[0] as List<AppUser>;
        _projectDirectory = results[1] as List<WorkspaceProject>;
      });
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('Failed to refresh admin directory: $error');
    }
  }

  Future<void> _loadSelectedSection() {
    switch (_selectedTab) {
      case 0:
        return _loadUsers();
      case 1:
        return _loadProjects();
      case 2:
        return _loadTasks();
      case 3:
        return _loadTags();
      case 4:
        return _loadFiles();
      case 5:
        return _loadReminders();
      default:
        return Future<void>.value();
    }
  }

  Future<void> _loadUsers() async {
    setState(() => _loadingUsers = true);
    try {
      final users = await _adminService.listUsers(
        query: _userQuery.isEmpty ? null : _userQuery,
        systemRole: _userRole == 'all' ? null : _userRole,
        provider: _userProvider == 'all' ? null : _userProvider,
      );

      if (!mounted) {
        return;
      }

      setState(() => _users = users);
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('Failed to load users: $error');
    } finally {
      if (mounted) {
        setState(() => _loadingUsers = false);
      }
    }
  }

  Future<void> _loadProjects() async {
    setState(() => _loadingProjects = true);
    try {
      final projects = await _adminService.listProjects(
        query: _projectQuery.isEmpty ? null : _projectQuery,
        visibility: _projectVisibility == 'all' ? null : _projectVisibility,
        createdByUserId: _projectCreatorId,
        ownerUserId: _projectOwnerId,
      );

      if (!mounted) {
        return;
      }

      setState(() => _projects = projects);
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('Failed to load projects: $error');
    } finally {
      if (mounted) {
        setState(() => _loadingProjects = false);
      }
    }
  }

  Future<void> _loadTasks() async {
    setState(() => _loadingTasks = true);
    try {
      final tasks = await _adminService.listTasks(
        query: _taskQuery.isEmpty ? null : _taskQuery,
        projectId: _taskProjectId,
        status: _taskStatus == 'all' ? null : _taskStatus,
        priority: _taskPriority == 'all' ? null : _taskPriority,
        createdByUserId: _taskCreatorId,
      );

      if (!mounted) {
        return;
      }

      setState(() => _tasks = tasks);
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('Failed to load tasks: $error');
    } finally {
      if (mounted) {
        setState(() => _loadingTasks = false);
      }
    }
  }

  Future<void> _loadTags() async {
    setState(() => _loadingTags = true);
    try {
      final tags = await _adminService.listTags(
        query: _tagQuery.isEmpty ? null : _tagQuery,
        projectId: _tagProjectId,
        createdByUserId: _tagCreatorId,
      );

      if (!mounted) {
        return;
      }

      setState(() => _tags = tags);
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('Failed to load tags: $error');
    } finally {
      if (mounted) {
        setState(() => _loadingTags = false);
      }
    }
  }

  Future<void> _loadFiles() async {
    setState(() => _loadingFiles = true);
    try {
      final files = await _adminService.listFiles(
        query: _fileQuery.isEmpty ? null : _fileQuery,
        kind: _fileKind == 'all' ? null : _fileKind,
        ownerType: _fileOwnerType == 'all' ? null : _fileOwnerType,
        uploadedByUserId: _fileUploaderId,
      );

      if (!mounted) {
        return;
      }

      setState(() => _files = files);
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('Failed to load files: $error');
    } finally {
      if (mounted) {
        setState(() => _loadingFiles = false);
      }
    }
  }

  Future<void> _loadReminders() async {
    setState(() => _loadingReminders = true);
    try {
      final reminders = await _adminService.listReminders(
        query: _reminderQuery.isEmpty ? null : _reminderQuery,
        userId: _reminderUserId,
        isCompleted:
            _reminderCompleted == 'all' ? null : _reminderCompleted == 'done',
      );

      if (!mounted) {
        return;
      }

      setState(() => _reminders = reminders);
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('Failed to load reminders: $error');
    } finally {
      if (mounted) {
        setState(() => _loadingReminders = false);
      }
    }
  }

  Future<DateTime?> _pickDateTime({DateTime? initialValue}) async {
    final initial = initialValue ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) {
      return null;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) {
      return null;
    }

    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  Future<bool> _confirmAction({
    required String title,
    required String message,
    String confirmLabel = 'DELETE',
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: Text(title, style: AppTextStyles.titleMedium),
        content: Text(message, style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              confirmLabel,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    return confirmed == true;
  }

  String? _nullableDropdownValue(String? value) {
    return value == null || value.isEmpty ? null : value;
  }

  bool _isFilterPanelExpanded(int tabIndex) {
    return _filterPanelsExpanded[tabIndex] ?? false;
  }

  void _setFilterPanelExpanded(int tabIndex, bool expanded) {
    setState(() => _filterPanelsExpanded[tabIndex] = expanded);
  }

  String _userLabel(String? userId) {
    if (userId == null || userId.isEmpty) {
      return 'all users';
    }

    for (final user in _userDirectory) {
      if (user.id == userId) {
        return user.resolvedDisplayName;
      }
    }

    return userId;
  }

  String _projectLabel(String? projectId) {
    if (projectId == null || projectId.isEmpty) {
      return 'all projects';
    }

    for (final project in _projectDirectory) {
      if (project.id == projectId) {
        return project.name;
      }
    }

    return projectId;
  }

  String _filterSummary(
    Iterable<String> tokens, {
    required String emptyMessage,
  }) {
    final active = tokens.where((token) => token.trim().isNotEmpty).toList();
    return active.isEmpty ? emptyMessage : active.join(' · ');
  }

  String get _userFiltersSummary => _filterSummary(
        <String>[
          if (_userQuery.trim().isNotEmpty) 'Search "${_userQuery.trim()}"',
          if (_userRole != 'all') 'Role ${_userRole.toUpperCase()}',
          if (_userProvider != 'all') 'Provider ${_userProvider.toUpperCase()}',
        ],
        emptyMessage: 'Tap to search and filter users.',
      );

  String get _projectFiltersSummary => _filterSummary(
        <String>[
          if (_projectQuery.trim().isNotEmpty)
            'Search "${_projectQuery.trim()}"',
          if (_projectVisibility != 'all')
            'Visibility ${_projectVisibility.toUpperCase()}',
          if (_projectOwnerId != null) 'Owner ${_userLabel(_projectOwnerId)}',
          if (_projectCreatorId != null)
            'Creator ${_userLabel(_projectCreatorId)}',
        ],
        emptyMessage: 'Tap to search and filter projects.',
      );

  String get _taskFiltersSummary => _filterSummary(
        <String>[
          if (_taskQuery.trim().isNotEmpty) 'Search "${_taskQuery.trim()}"',
          if (_taskProjectId != null)
            'Project ${_projectLabel(_taskProjectId)}',
          if (_taskStatus != 'all') 'Status ${titleCaseToken(_taskStatus)}',
          if (_taskPriority != 'all')
            'Priority ${titleCaseToken(_taskPriority)}',
          if (_taskCreatorId != null) 'Creator ${_userLabel(_taskCreatorId)}',
        ],
        emptyMessage: 'Tap to search and filter tasks.',
      );

  String get _tagFiltersSummary => _filterSummary(
        <String>[
          if (_tagQuery.trim().isNotEmpty) 'Search "${_tagQuery.trim()}"',
          if (_tagProjectId != null) 'Project ${_projectLabel(_tagProjectId)}',
          if (_tagCreatorId != null) 'Creator ${_userLabel(_tagCreatorId)}',
        ],
        emptyMessage: 'Tap to search and filter tags.',
      );

  String get _fileFiltersSummary => _filterSummary(
        <String>[
          if (_fileQuery.trim().isNotEmpty) 'Search "${_fileQuery.trim()}"',
          if (_fileKind != 'all') 'Kind ${_fileKind.toUpperCase()}',
          if (_fileOwnerType != 'all')
            'Owner ${titleCaseToken(_fileOwnerType)}',
          if (_fileUploaderId != null)
            'Uploader ${_userLabel(_fileUploaderId)}',
        ],
        emptyMessage: 'Tap to search and filter files.',
      );

  String get _reminderFiltersSummary => _filterSummary(
        <String>[
          if (_reminderQuery.trim().isNotEmpty)
            'Search "${_reminderQuery.trim()}"',
          if (_reminderUserId != null) 'User ${_userLabel(_reminderUserId)}',
          if (_reminderCompleted != 'all')
            'Completion ${titleCaseToken(_reminderCompleted)}',
        ],
        emptyMessage: 'Tap to search and filter reminders.',
      );

  Widget _buildFilterPanel({
    required int tabIndex,
    required String title,
    required String summary,
    required Widget child,
  }) {
    return ExpandableFilterPanel(
      title: title,
      summary: summary,
      expanded: _isFilterPanelExpanded(tabIndex),
      onExpandedChanged: (expanded) =>
          _setFilterPanelExpanded(tabIndex, expanded),
      collapsedHint: 'Tap to expand $title search and filters.',
      child: child,
    );
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
      title: 'Admin Console',
      trailing: IconButton(
        onPressed: _loadingAccess
            ? null
            : () async {
                await _refreshDirectories();
                await _loadSelectedSection();
              },
        icon: const Icon(Icons.refresh, color: AppColors.primary),
      ),
      child: _loadingAccess
          ? const Center(child: CircularProgressIndicator())
          : _forbidden
              ? const Center(
                  child: WorkspaceEmptyState(
                    icon: Icons.lock_outline,
                    title: 'Admin Access Required',
                    message:
                        'This console is only available to admins. Member workspaces stay separated from admin write flows.',
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Use this hub for system-wide admin search and write workflows. Outside the console, admins only see the same projects and files they personally belong to or own.',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SegmentedTabBar(
                      tabs: const [
                        'Users',
                        'Projects',
                        'Tasks',
                        'Tags',
                        'Files',
                        'Reminders',
                      ],
                      selectedIndex: _selectedTab,
                      onSelected: (index) {
                        setState(() => _selectedTab = index);
                        _loadSelectedSection();
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Expanded(
                      child: switch (_selectedTab) {
                        0 => _buildUsersSection(),
                        1 => _buildProjectsSection(),
                        2 => _buildTasksSection(),
                        3 => _buildTagsSection(),
                        4 => _buildFilesSection(),
                        5 => _buildRemindersSection(),
                        _ => const SizedBox.shrink(),
                      },
                    ),
                  ],
                ),
    );
  }

  Widget _buildSectionShell({
    required Widget filters,
    required Widget list,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        filters,
        const SizedBox(height: AppSpacing.md),
        Expanded(child: list),
      ],
    );
  }

  Widget _buildUsersSection() {
    return _buildSectionShell(
      filters: _buildFilterPanel(
        tabIndex: 0,
        title: 'Users',
        summary: _userFiltersSummary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              onChanged: (value) => setState(() => _userQuery = value),
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Search username, email, or display name',
                suffixIcon: IconButton(
                  onPressed: _loadingUsers ? null : _loadUsers,
                  icon: const Icon(Icons.search, color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                final roleDropdown = DropdownButtonFormField<String>(
                  initialValue: _userRole,
                  dropdownColor: AppColors.bgCard,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('ALL')),
                    DropdownMenuItem(value: 'member', child: Text('MEMBER')),
                    DropdownMenuItem(value: 'admin', child: Text('ADMIN')),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() => _userRole = value);
                    _loadUsers();
                  },
                );

                final providerDropdown = DropdownButtonFormField<String>(
                  initialValue: _userProvider,
                  dropdownColor: AppColors.bgCard,
                  decoration: const InputDecoration(labelText: 'Provider'),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('ALL')),
                    DropdownMenuItem(value: 'local', child: Text('LOCAL')),
                    DropdownMenuItem(value: 'google', child: Text('GOOGLE')),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() => _userProvider = value);
                    _loadUsers();
                  },
                );

                final createButton = MechaButton(
                  label: 'CREATE USER',
                  onTap: _showCreateUserDialog,
                );

                if (constraints.maxWidth < 780) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      roleDropdown,
                      const SizedBox(height: AppSpacing.md),
                      providerDropdown,
                      const SizedBox(height: AppSpacing.md),
                      createButton,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: roleDropdown),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: providerDropdown),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: createButton),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      list: _loadingUsers
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? const WorkspaceEmptyState(
                  icon: Icons.people_outline,
                  title: 'No Users Found',
                  message:
                      'Adjust the filters or create a user from the admin console.',
                )
              : ListView.separated(
                  itemCount: _users.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    final isBusy = _busyId == user.id;

                    return MechaPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.resolvedDisplayName,
                                      style: AppTextStyles.titleMedium,
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      '@${user.username} · ${user.email ?? 'no email'}',
                                      style: AppTextStyles.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              _AdminMetaBadge(
                                label: user.systemRole.toUpperCase(),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              _AdminMetaBadge(
                                label:
                                    'PROVIDER ${(user.authProvider ?? 'unknown').toUpperCase()}',
                              ),
                              _AdminMetaBadge(
                                label:
                                    'LAST LOGIN ${formatShortDate(user.lastLoginAt)}',
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          ResponsiveActionGroup(
                            breakpoint: 720,
                            children: [
                              MechaButton(
                                label: 'DETAIL',
                                variant: MechaButtonVariant.outlined,
                                onTap: () => _showUserDetailDialog(user),
                              ),
                              MechaButton(
                                label: 'EDIT',
                                variant: MechaButtonVariant.outlined,
                                onTap: () => _showEditUserDialog(user),
                              ),
                              MechaButton(
                                label: isBusy ? '...' : 'DELETE',
                                onTap: isBusy ? null : () => _deleteUser(user),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Future<void> _showCreateUserDialog() async {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final emailController = TextEditingController();
    final displayNameController = TextEditingController();
    final bioController = TextEditingController();
    var systemRole = 'member';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          title: Text('Create User', style: AppTextStyles.titleMedium),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MechaTextField(
                  label: 'USERNAME',
                  hint: 'new_user',
                  controller: usernameController,
                ),
                const SizedBox(height: AppSpacing.md),
                MechaTextField(
                  label: 'PASSWORD',
                  hint: 'Temporary password',
                  controller: passwordController,
                  isPassword: true,
                ),
                const SizedBox(height: AppSpacing.md),
                MechaTextField(
                  label: 'EMAIL',
                  hint: 'user@example.com',
                  controller: emailController,
                ),
                const SizedBox(height: AppSpacing.md),
                MechaTextField(
                  label: 'DISPLAY NAME',
                  hint: 'Display name',
                  controller: displayNameController,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: bioController,
                  minLines: 3,
                  maxLines: 4,
                  style: AppTextStyles.bodyMedium,
                  decoration: const InputDecoration(hintText: 'Short bio'),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: systemRole,
                  dropdownColor: AppColors.bgCard,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(value: 'member', child: Text('MEMBER')),
                    DropdownMenuItem(value: 'admin', child: Text('ADMIN')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => systemRole = value);
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
                'CREATE',
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

    try {
      await _adminService.createUser(
        username: usernameController.text.trim(),
        password: passwordController.text.trim(),
        email: emailController.text.trim().isEmpty
            ? null
            : emailController.text.trim(),
        systemRole: systemRole,
        displayName: displayNameController.text.trim(),
        bio: bioController.text.trim(),
      );
      _showMessage('User created.', isError: false);
      await _refreshDirectories();
      await _loadUsers();
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('User creation failed: $error');
    }
  }

  Future<void> _showEditUserDialog(AppUser user) async {
    final usernameController = TextEditingController(text: user.username);
    final passwordController = TextEditingController();
    final emailController = TextEditingController(text: user.email ?? '');
    final displayNameController =
        TextEditingController(text: user.displayName ?? '');
    final bioController = TextEditingController(text: user.bio ?? '');
    var systemRole = user.systemRole;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          title: Text('Edit User', style: AppTextStyles.titleMedium),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MechaTextField(
                  label: 'USERNAME',
                  hint: 'username',
                  controller: usernameController,
                ),
                const SizedBox(height: AppSpacing.md),
                MechaTextField(
                  label: 'NEW PASSWORD',
                  hint: 'Leave blank to keep current',
                  controller: passwordController,
                  isPassword: true,
                ),
                const SizedBox(height: AppSpacing.md),
                MechaTextField(
                  label: 'EMAIL',
                  hint: 'user@example.com',
                  controller: emailController,
                ),
                const SizedBox(height: AppSpacing.md),
                MechaTextField(
                  label: 'DISPLAY NAME',
                  hint: 'Display name',
                  controller: displayNameController,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: bioController,
                  minLines: 3,
                  maxLines: 4,
                  style: AppTextStyles.bodyMedium,
                  decoration: const InputDecoration(hintText: 'Short bio'),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: systemRole,
                  dropdownColor: AppColors.bgCard,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(value: 'member', child: Text('MEMBER')),
                    DropdownMenuItem(value: 'admin', child: Text('ADMIN')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => systemRole = value);
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

    try {
      await _adminService.updateUser(
        user.id,
        username: usernameController.text.trim(),
        password: passwordController.text.trim().isEmpty
            ? null
            : passwordController.text.trim(),
        email: emailController.text.trim(),
        systemRole: systemRole,
        displayName: displayNameController.text.trim(),
        bio: bioController.text.trim(),
      );
      _showMessage('User updated.', isError: false);
      await _refreshDirectories();
      await _loadUsers();
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('User update failed: $error');
    }
  }

  Future<void> _showUserDetailDialog(AppUser user) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: Text(user.resolvedDisplayName, style: AppTextStyles.titleMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('@${user.username}', style: AppTextStyles.bodyMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(user.email ?? 'No email', style: AppTextStyles.bodySmall),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _AdminMetaBadge(label: 'ROLE ${user.systemRole.toUpperCase()}'),
                _AdminMetaBadge(
                  label:
                      'PROVIDER ${(user.authProvider ?? 'unknown').toUpperCase()}',
                ),
                _AdminMetaBadge(
                  label: 'CREATED ${formatShortDate(user.createdAt)}',
                ),
              ],
            ),
            if ((user.bio ?? '').isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(user.bio!, style: AppTextStyles.bodySmall),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser(AppUser user) async {
    final confirmed = await _confirmAction(
      title: 'Delete ${user.username}?',
      message: 'This removes the user account from the system.',
    );
    if (!confirmed) {
      return;
    }

    setState(() => _busyId = user.id);
    try {
      await _adminService.deleteUser(user.id);
      _showMessage('User deleted.', isError: false);
      await _refreshDirectories();
      await _loadUsers();
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('Delete failed: $error');
    } finally {
      if (mounted) {
        setState(() => _busyId = null);
      }
    }
  }

  Widget _buildProjectsSection() {
    return _buildSectionShell(
      filters: _buildFilterPanel(
        tabIndex: 1,
        title: 'Projects',
        summary: _projectFiltersSummary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              onChanged: (value) => setState(() => _projectQuery = value),
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Search project name or description',
                suffixIcon: IconButton(
                  onPressed: _loadingProjects ? null : _loadProjects,
                  icon: const Icon(Icons.search, color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _projectVisibility,
              dropdownColor: AppColors.bgCard,
              decoration: const InputDecoration(labelText: 'Visibility'),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('ALL')),
                DropdownMenuItem(value: 'private', child: Text('PRIVATE')),
                DropdownMenuItem(value: 'shared', child: Text('SHARED')),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() => _projectVisibility = value);
                _loadProjects();
              },
            ),
            const SizedBox(height: AppSpacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                final ownerDropdown = DropdownButtonFormField<String?>(
                  initialValue: _nullableDropdownValue(_projectOwnerId),
                  dropdownColor: AppColors.bgCard,
                  decoration: const InputDecoration(labelText: 'Owner'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('ALL OWNERS'),
                    ),
                    ..._userDirectory.map(
                      (user) => DropdownMenuItem<String?>(
                        value: user.id,
                        child: Text(user.resolvedDisplayName),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _projectOwnerId = value);
                    _loadProjects();
                  },
                );

                final creatorDropdown = DropdownButtonFormField<String?>(
                  initialValue: _nullableDropdownValue(_projectCreatorId),
                  dropdownColor: AppColors.bgCard,
                  decoration: const InputDecoration(labelText: 'Creator'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('ALL CREATORS'),
                    ),
                    ..._userDirectory.map(
                      (user) => DropdownMenuItem<String?>(
                        value: user.id,
                        child: Text(user.resolvedDisplayName),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _projectCreatorId = value);
                    _loadProjects();
                  },
                );

                final createButton = MechaButton(
                  label: 'CREATE PROJECT',
                  onTap: _showCreateProjectDialog,
                );

                if (constraints.maxWidth < 860) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ownerDropdown,
                      const SizedBox(height: AppSpacing.md),
                      creatorDropdown,
                      const SizedBox(height: AppSpacing.md),
                      createButton,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: ownerDropdown),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: creatorDropdown),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: createButton),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      list: _loadingProjects
          ? const Center(child: CircularProgressIndicator())
          : _projects.isEmpty
              ? const WorkspaceEmptyState(
                  icon: Icons.dashboard_customize_outlined,
                  title: 'No Projects Found',
                  message:
                      'Adjust the filters or create a project from the admin console.',
                )
              : ListView.separated(
                  itemCount: _projects.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final project = _projects[index];
                    final isBusy = _busyId == project.id;

                    return MechaPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      project.name,
                                      style: AppTextStyles.titleMedium,
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      project.description.isEmpty
                                          ? 'No description.'
                                          : project.description,
                                      style: AppTextStyles.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              _AdminMetaBadge(
                                label: project.visibility.toUpperCase(),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              if (project.createdByUser != null)
                                _AdminMetaBadge(
                                  label:
                                      'CREATOR ${project.createdByUser!.resolvedDisplayName.toUpperCase()}',
                                ),
                              _AdminMetaBadge(
                                label:
                                    'OWNERS ${project.ownerUsers.isEmpty ? '-' : project.ownerUsers.length}',
                              ),
                              _AdminMetaBadge(
                                label:
                                    'MEMBERS ${project.acceptedMemberCount ?? 0}',
                              ),
                              _AdminMetaBadge(
                                label:
                                    'INVITES ${project.pendingInviteCount ?? 0}',
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          ResponsiveActionGroup(
                            breakpoint: 760,
                            children: [
                              MechaButton(
                                label: 'DETAIL',
                                variant: MechaButtonVariant.outlined,
                                onTap: () => _showProjectDetailDialog(project),
                              ),
                              MechaButton(
                                label: isBusy ? '...' : 'DELETE',
                                onTap: isBusy
                                    ? null
                                    : () => _deleteProject(project),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Future<void> _showCreateProjectDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    var visibility = 'private';
    String? ownerUserId =
        _userDirectory.isNotEmpty ? _userDirectory.first.id : null;
    String? creatorUserId = ownerUserId;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          title: Text('Create Project', style: AppTextStyles.titleMedium),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MechaTextField(
                  label: 'NAME',
                  hint: 'Project name',
                  controller: nameController,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: descriptionController,
                  minLines: 3,
                  maxLines: 4,
                  style: AppTextStyles.bodyMedium,
                  decoration: const InputDecoration(hintText: 'Description'),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: visibility,
                  dropdownColor: AppColors.bgCard,
                  decoration: const InputDecoration(labelText: 'Visibility'),
                  items: const [
                    DropdownMenuItem(value: 'private', child: Text('PRIVATE')),
                    DropdownMenuItem(value: 'shared', child: Text('SHARED')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => visibility = value);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: _nullableDropdownValue(ownerUserId),
                  dropdownColor: AppColors.bgCard,
                  decoration: const InputDecoration(labelText: 'Owner'),
                  items: _userDirectory
                      .map(
                        (user) => DropdownMenuItem<String>(
                          value: user.id,
                          child: Text(user.resolvedDisplayName),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    setDialogState(() {
                      ownerUserId = value;
                      creatorUserId ??= value;
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: _nullableDropdownValue(creatorUserId),
                  dropdownColor: AppColors.bgCard,
                  decoration: const InputDecoration(labelText: 'Creator'),
                  items: _userDirectory
                      .map(
                        (user) => DropdownMenuItem<String>(
                          value: user.id,
                          child: Text(user.resolvedDisplayName),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) =>
                      setDialogState(() => creatorUserId = value),
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
                'CREATE',
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

    try {
      await _adminService.createProject(
        name: nameController.text.trim(),
        description: descriptionController.text.trim(),
        visibility: visibility,
        ownerUserId: ownerUserId,
        createdByUserId: creatorUserId,
      );
      _showMessage('Project created.', isError: false);
      await _refreshDirectories();
      await _loadProjects();
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('Project creation failed: $error');
    }
  }

  Future<void> _showEditProjectDialog(WorkspaceProject project) async {
    final nameController = TextEditingController(text: project.name);
    final descriptionController =
        TextEditingController(text: project.description);
    var visibility = project.visibility;
    String? creatorUserId = project.createdBy;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          title: Text('Edit Project', style: AppTextStyles.titleMedium),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MechaTextField(
                  label: 'NAME',
                  hint: 'Project name',
                  controller: nameController,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: descriptionController,
                  minLines: 3,
                  maxLines: 4,
                  style: AppTextStyles.bodyMedium,
                  decoration: const InputDecoration(hintText: 'Description'),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: visibility,
                  dropdownColor: AppColors.bgCard,
                  decoration: const InputDecoration(labelText: 'Visibility'),
                  items: const [
                    DropdownMenuItem(value: 'private', child: Text('PRIVATE')),
                    DropdownMenuItem(value: 'shared', child: Text('SHARED')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => visibility = value);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: _nullableDropdownValue(creatorUserId),
                  dropdownColor: AppColors.bgCard,
                  decoration: const InputDecoration(labelText: 'Creator'),
                  items: _userDirectory
                      .map(
                        (user) => DropdownMenuItem<String>(
                          value: user.id,
                          child: Text(user.resolvedDisplayName),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) =>
                      setDialogState(() => creatorUserId = value),
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

    try {
      await _adminService.updateProject(
        project.id,
        name: nameController.text.trim(),
        description: descriptionController.text.trim(),
        visibility: visibility,
        createdByUserId: creatorUserId,
      );
      _showMessage('Project updated.', isError: false);
      await _refreshDirectories();
      await _loadProjects();
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('Project update failed: $error');
    }
  }

  Future<void> _showProjectDetailDialog(WorkspaceProject project) async {
    final detail = await _adminService.getProject(project.id);
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          title: Text(detail.name, style: AppTextStyles.titleMedium),
          content: SizedBox(
            width: 620,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    detail.description.isEmpty
                        ? 'No project description.'
                        : detail.description,
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _AdminMetaBadge(label: detail.visibility.toUpperCase()),
                      if (detail.createdByUser != null)
                        _AdminMetaBadge(
                          label:
                              'CREATOR ${detail.createdByUser!.resolvedDisplayName.toUpperCase()}',
                        ),
                      _AdminMetaBadge(
                        label: 'MEMBERS ${detail.acceptedMemberCount ?? 0}',
                      ),
                      _AdminMetaBadge(
                        label: 'INVITES ${detail.pendingInviteCount ?? 0}',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ResponsiveActionGroup(
                    breakpoint: 700,
                    children: [
                      MechaButton(
                        label: 'EDIT PROJECT',
                        variant: MechaButtonVariant.outlined,
                        onTap: () {
                          Navigator.pop(context);
                          _showEditProjectDialog(detail);
                        },
                      ),
                      MechaButton(
                        label: 'ADD MEMBER',
                        onTap: () {
                          Navigator.pop(context);
                          _showAddProjectMemberDialog(detail);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('Accepted Members', style: AppTextStyles.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  if (detail.members.isEmpty)
                    Text(
                      'No accepted members yet.',
                      style: AppTextStyles.bodySmall,
                    )
                  else
                    for (final member in detail.members)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${member.user?.resolvedDisplayName ?? member.userId} · ${member.role.toUpperCase()}',
                                style: AppTextStyles.bodySmall,
                              ),
                            ),
                            TextButton(
                              onPressed: () => _showUpdateProjectMemberDialog(
                                  detail, member),
                              child: Text(
                                'ROLE',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  _removeProjectMember(detail, member),
                              child: const Text(
                                'REMOVE',
                                style: TextStyle(color: Colors.redAccent),
                              ),
                            ),
                          ],
                        ),
                      ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Pending Invitations',
                          style: AppTextStyles.titleMedium,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showProjectInviteDialog(detail);
                        },
                        child: Text(
                          'INVITE',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (detail.pendingInvites.isEmpty)
                    Text(
                      'No pending invites.',
                      style: AppTextStyles.bodySmall,
                    )
                  else
                    for (final invite in detail.pendingInvites)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${invite.invitee?.resolvedDisplayName ?? invite.inviteeUserId} · ${invite.role.toUpperCase()}',
                                style: AppTextStyles.bodySmall,
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  _removeProjectInvite(detail, invite),
                              child: const Text(
                                'REMOVE',
                                style: TextStyle(color: Colors.redAccent),
                              ),
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CLOSE'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteProject(WorkspaceProject project) async {
    final confirmed = await _confirmAction(
      title: 'Delete ${project.name}?',
      message: 'This removes the entire project tree and related records.',
    );
    if (!confirmed) {
      return;
    }

    setState(() => _busyId = project.id);
    try {
      await _adminService.deleteProject(project.id);
      _showMessage('Project deleted.', isError: false);
      await _refreshDirectories();
      await _loadProjects();
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('Delete failed: $error');
    } finally {
      if (mounted) {
        setState(() => _busyId = null);
      }
    }
  }

  Future<void> _showAddProjectMemberDialog(WorkspaceProject project) async {
    String? userId = _userDirectory.isNotEmpty ? _userDirectory.first.id : null;
    var role = 'viewer';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          title: Text('Add Project Member', style: AppTextStyles.titleMedium),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _nullableDropdownValue(userId),
                dropdownColor: AppColors.bgCard,
                decoration: const InputDecoration(labelText: 'User'),
                items: _userDirectory
                    .map(
                      (user) => DropdownMenuItem<String>(
                        value: user.id,
                        child: Text(user.resolvedDisplayName),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) => setDialogState(() => userId = value),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: role,
                dropdownColor: AppColors.bgCard,
                decoration: const InputDecoration(labelText: 'Role'),
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'ADD',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || userId == null) {
      return;
    }

    try {
      await _adminService.addProjectMember(project.id,
          userId: userId!, role: role);
      _showMessage('Member added.', isError: false);
      await _refreshDirectories();
      await _loadProjects();
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('Member add failed: $error');
    }
  }

  Future<void> _showProjectInviteDialog(WorkspaceProject project) async {
    String? userId = _userDirectory.isNotEmpty ? _userDirectory.first.id : null;
    var role = 'viewer';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          title:
              Text('Create Project Invite', style: AppTextStyles.titleMedium),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _nullableDropdownValue(userId),
                dropdownColor: AppColors.bgCard,
                decoration: const InputDecoration(labelText: 'Invitee'),
                items: _userDirectory
                    .map(
                      (user) => DropdownMenuItem<String>(
                        value: user.id,
                        child: Text(user.resolvedDisplayName),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) => setDialogState(() => userId = value),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: role,
                dropdownColor: AppColors.bgCard,
                decoration: const InputDecoration(labelText: 'Role'),
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'INVITE',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || userId == null) {
      return;
    }

    try {
      await _adminService.createProjectInvite(project.id,
          userId: userId!, role: role);
      _showMessage('Invite created.', isError: false);
      await _loadProjects();
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('Invite creation failed: $error');
    }
  }

  Future<void> _showUpdateProjectMemberDialog(
    WorkspaceProject project,
    ProjectMember member,
  ) async {
    var role = member.role;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          title: Text('Update Member Role', style: AppTextStyles.titleMedium),
          content: DropdownButtonFormField<String>(
            initialValue: role,
            dropdownColor: AppColors.bgCard,
            decoration: const InputDecoration(labelText: 'Role'),
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

    try {
      await _adminService.updateProjectMember(project.id, member.id,
          role: role);
      _showMessage('Member updated.', isError: false);
      await _loadProjects();
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('Member update failed: $error');
    }
  }

  Future<void> _removeProjectMember(
    WorkspaceProject project,
    ProjectMember member,
  ) async {
    final confirmed = await _confirmAction(
      title: 'Remove ${member.user?.resolvedDisplayName ?? member.userId}?',
      message: 'This removes the member from the project.',
      confirmLabel: 'REMOVE',
    );
    if (!confirmed) {
      return;
    }

    try {
      await _adminService.deleteProjectMember(project.id, member.id);
      _showMessage('Member removed.', isError: false);
      await _loadProjects();
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('Member removal failed: $error');
    }
  }

  Future<void> _removeProjectInvite(
    WorkspaceProject project,
    ProjectInvite invite,
  ) async {
    final confirmed = await _confirmAction(
      title: 'Remove invite?',
      message:
          'This removes the pending invite for ${invite.invitee?.resolvedDisplayName ?? invite.inviteeUserId}.',
      confirmLabel: 'REMOVE',
    );
    if (!confirmed) {
      return;
    }

    try {
      await _adminService.deleteProjectInvite(project.id, invite.id);
      _showMessage('Invite removed.', isError: false);
      await _loadProjects();
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('Invite removal failed: $error');
    }
  }

  Widget _buildTasksSection() {
    return _buildSectionShell(
      filters: _buildFilterPanel(
        tabIndex: 2,
        title: 'Tasks',
        summary: _taskFiltersSummary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              onChanged: (value) => setState(() => _taskQuery = value),
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Search task title or description',
                suffixIcon: IconButton(
                  onPressed: _loadingTasks ? null : _loadTasks,
                  icon: const Icon(Icons.search, color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String?>(
                    initialValue: _nullableDropdownValue(_taskProjectId),
                    dropdownColor: AppColors.bgCard,
                    decoration: const InputDecoration(labelText: 'Project'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('ALL PROJECTS'),
                      ),
                      ..._projectDirectory.map(
                        (project) => DropdownMenuItem<String?>(
                          value: project.id,
                          child: Text(project.name),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _taskProjectId = value);
                      _loadTasks();
                    },
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String?>(
                    initialValue: _taskStatus,
                    dropdownColor: AppColors.bgCard,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('ALL')),
                      DropdownMenuItem(value: 'todo', child: Text('TODO')),
                      DropdownMenuItem(
                        value: 'in_progress',
                        child: Text('IN PROGRESS'),
                      ),
                      DropdownMenuItem(value: 'done', child: Text('DONE')),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() => _taskStatus = value);
                      _loadTasks();
                    },
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String>(
                    initialValue: _taskPriority,
                    dropdownColor: AppColors.bgCard,
                    decoration: const InputDecoration(labelText: 'Priority'),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('ALL')),
                      DropdownMenuItem(value: 'low', child: Text('LOW')),
                      DropdownMenuItem(value: 'medium', child: Text('MEDIUM')),
                      DropdownMenuItem(value: 'high', child: Text('HIGH')),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() => _taskPriority = value);
                      _loadTasks();
                    },
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String?>(
                    initialValue: _nullableDropdownValue(_taskCreatorId),
                    dropdownColor: AppColors.bgCard,
                    decoration: const InputDecoration(labelText: 'Creator'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('ALL CREATORS'),
                      ),
                      ..._userDirectory.map(
                        (user) => DropdownMenuItem<String?>(
                          value: user.id,
                          child: Text(user.resolvedDisplayName),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _taskCreatorId = value);
                      _loadTasks();
                    },
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: MechaButton(
                    label: 'CREATE TASK',
                    onTap: _showCreateTaskDialog,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      list: _loadingTasks
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
              ? const WorkspaceEmptyState(
                  icon: Icons.assignment_outlined,
                  title: 'No Tasks Found',
                  message:
                      'Adjust the filters or create a task from the admin console.',
                )
              : ListView.separated(
                  itemCount: _tasks.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final task = _tasks[index];
                    final isBusy = _busyId == task.id;

                    return MechaPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  task.title,
                                  style: AppTextStyles.titleMedium,
                                ),
                              ),
                              _AdminMetaBadge(
                                label:
                                    titleCaseToken(task.status).toUpperCase(),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              _AdminMetaBadge(
                                label: task.priority.toUpperCase(),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            task.project?.name ?? task.projectId,
                            style: AppTextStyles.bodySmall,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          ResponsiveActionGroup(
                            breakpoint: 760,
                            children: [
                              MechaButton(
                                label: 'DETAIL',
                                variant: MechaButtonVariant.outlined,
                                onTap: () => _showTaskDetailDialog(task),
                              ),
                              MechaButton(
                                label: isBusy ? '...' : 'DELETE',
                                onTap: isBusy ? null : () => _deleteTask(task),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Future<void> _showCreateTaskDialog() async {
    await _showTaskEditor();
  }

  Future<void> _showEditTaskDialog(TaskItem task) async {
    await _showTaskEditor(task: task);
  }

  Future<void> _showTaskEditor({TaskItem? task}) async {
    String? projectId = task?.projectId ??
        _taskProjectId ??
        (_projectDirectory.isNotEmpty ? _projectDirectory.first.id : null);
    String? creatorUserId = task?.createdBy ??
        (_userDirectory.isNotEmpty ? _userDirectory.first.id : null);
    final titleController = TextEditingController(text: task?.title ?? '');
    final descriptionController =
        TextEditingController(text: task?.description ?? '');
    var status = task?.status ?? 'todo';
    var priority = task?.priority ?? 'medium';
    var reminderAt = task?.reminderAt;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          title: Text(
            task == null ? 'Create Task' : 'Edit Task',
            style: AppTextStyles.titleMedium,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _nullableDropdownValue(projectId),
                  dropdownColor: AppColors.bgCard,
                  decoration: const InputDecoration(labelText: 'Project'),
                  items: _projectDirectory
                      .map(
                        (project) => DropdownMenuItem<String>(
                          value: project.id,
                          child: Text(project.name),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) => setDialogState(() => projectId = value),
                ),
                const SizedBox(height: AppSpacing.md),
                MechaTextField(
                  label: 'TITLE',
                  hint: 'Task title',
                  controller: titleController,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: descriptionController,
                  minLines: 3,
                  maxLines: 4,
                  style: AppTextStyles.bodyMedium,
                  decoration: const InputDecoration(hintText: 'Description'),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  dropdownColor: AppColors.bgCard,
                  decoration: const InputDecoration(labelText: 'Status'),
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
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: priority,
                  dropdownColor: AppColors.bgCard,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('LOW')),
                    DropdownMenuItem(value: 'medium', child: Text('MEDIUM')),
                    DropdownMenuItem(value: 'high', child: Text('HIGH')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => priority = value);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: _nullableDropdownValue(creatorUserId),
                  dropdownColor: AppColors.bgCard,
                  decoration: const InputDecoration(labelText: 'Creator'),
                  items: _userDirectory
                      .map(
                        (user) => DropdownMenuItem<String>(
                          value: user.id,
                          child: Text(user.resolvedDisplayName),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) =>
                      setDialogState(() => creatorUserId = value),
                ),
                const SizedBox(height: AppSpacing.md),
                MechaButton(
                  label: reminderAt == null
                      ? 'SET REMINDER'
                      : 'REMINDER ${formatShortDateTime(reminderAt)}',
                  variant: MechaButtonVariant.outlined,
                  onTap: () async {
                    final picked =
                        await _pickDateTime(initialValue: reminderAt);
                    if (picked != null) {
                      setDialogState(() => reminderAt = picked);
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
                task == null ? 'CREATE' : 'SAVE',
                style: const TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || projectId == null) {
      return;
    }

    try {
      if (task == null) {
        await _adminService.createTask(
          projectId: projectId!,
          title: titleController.text.trim(),
          description: descriptionController.text.trim(),
          status: status,
          priority: priority,
          reminderAt: reminderAt,
          createdByUserId: creatorUserId,
          reminderUserId: creatorUserId,
        );
        _showMessage('Task created.', isError: false);
      } else {
        await _adminService.updateTask(
          task.id,
          title: titleController.text.trim(),
          description: descriptionController.text.trim(),
          status: status,
          priority: priority,
          reminderAt: reminderAt,
          clearReminder: reminderAt == null && task.reminderAt != null,
          createdByUserId: creatorUserId,
          reminderUserId: creatorUserId,
        );
        _showMessage('Task updated.', isError: false);
      }
      await _loadTasks();
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('Task save failed: $error');
    }
  }

  Future<void> _showTaskDetailDialog(TaskItem task) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: Text(task.title, style: AppTextStyles.titleMedium),
        content: SizedBox(
          width: 560,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.description.isEmpty ? 'No description.' : task.description,
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _AdminMetaBadge(label: task.status.toUpperCase()),
                  _AdminMetaBadge(label: task.priority.toUpperCase()),
                  if (task.project != null)
                    _AdminMetaBadge(
                        label: 'PROJECT ${task.project!.name.toUpperCase()}'),
                  if (task.creator != null)
                    _AdminMetaBadge(
                      label:
                          'CREATOR ${task.creator!.resolvedDisplayName.toUpperCase()}',
                    ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditTaskDialog(task);
            },
            child: const Text(
              'EDIT',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTask(TaskItem task) async {
    final confirmed = await _confirmAction(
      title: 'Delete ${task.title}?',
      message: 'This removes the task and related attachments/reminders.',
    );
    if (!confirmed) {
      return;
    }

    setState(() => _busyId = task.id);
    try {
      await _adminService.deleteTask(task.id);
      _showMessage('Task deleted.', isError: false);
      await _loadTasks();
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('Delete failed: $error');
    } finally {
      if (mounted) {
        setState(() => _busyId = null);
      }
    }
  }

  Widget _buildTagsSection() {
    return _buildSectionShell(
      filters: _buildFilterPanel(
        tabIndex: 3,
        title: 'Tags',
        summary: _tagFiltersSummary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              onChanged: (value) => setState(() => _tagQuery = value),
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Search tag name or color',
                suffixIcon: IconButton(
                  onPressed: _loadingTags ? null : _loadTags,
                  icon: const Icon(Icons.search, color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                SizedBox(
                  width: 240,
                  child: DropdownButtonFormField<String?>(
                    initialValue: _nullableDropdownValue(_tagProjectId),
                    dropdownColor: AppColors.bgCard,
                    decoration: const InputDecoration(labelText: 'Project'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('ALL PROJECTS'),
                      ),
                      ..._projectDirectory.map(
                        (project) => DropdownMenuItem<String?>(
                          value: project.id,
                          child: Text(project.name),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _tagProjectId = value);
                      _loadTags();
                    },
                  ),
                ),
                SizedBox(
                  width: 240,
                  child: DropdownButtonFormField<String?>(
                    initialValue: _nullableDropdownValue(_tagCreatorId),
                    dropdownColor: AppColors.bgCard,
                    decoration: const InputDecoration(labelText: 'Creator'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('ALL CREATORS'),
                      ),
                      ..._userDirectory.map(
                        (user) => DropdownMenuItem<String?>(
                          value: user.id,
                          child: Text(user.resolvedDisplayName),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _tagCreatorId = value);
                      _loadTags();
                    },
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: MechaButton(
                    label: 'CREATE TAG',
                    onTap: _showCreateTagDialog,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      list: _loadingTags
          ? const Center(child: CircularProgressIndicator())
          : _tags.isEmpty
              ? const WorkspaceEmptyState(
                  icon: Icons.sell_outlined,
                  title: 'No Tags Found',
                  message:
                      'Adjust the filters or create a tag from the admin console.',
                )
              : ListView.separated(
                  itemCount: _tags.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final tag = _tags[index];
                    final isBusy = _busyId == tag.id;

                    return MechaPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tag.name, style: AppTextStyles.titleMedium),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${tag.project?.name ?? tag.projectId} · ${tag.color}',
                            style: AppTextStyles.bodySmall,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          ResponsiveActionGroup(
                            breakpoint: 760,
                            children: [
                              MechaButton(
                                label: 'DETAIL',
                                variant: MechaButtonVariant.outlined,
                                onTap: () => _showTagDetailDialog(tag),
                              ),
                              MechaButton(
                                label: isBusy ? '...' : 'DELETE',
                                onTap: isBusy ? null : () => _deleteTag(tag),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Future<void> _showCreateTagDialog() async {
    await _showTagEditor();
  }

  Future<void> _showEditTagDialog(ProjectTag tag) async {
    await _showTagEditor(tag: tag);
  }

  Future<void> _showTagEditor({ProjectTag? tag}) async {
    String? projectId = tag?.projectId ??
        _tagProjectId ??
        (_projectDirectory.isNotEmpty ? _projectDirectory.first.id : null);
    String? creatorUserId = tag?.createdBy ??
        (_userDirectory.isNotEmpty ? _userDirectory.first.id : null);
    final nameController = TextEditingController(text: tag?.name ?? '');
    final colorController =
        TextEditingController(text: tag?.color ?? '#7dd3fc');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          title: Text(
            tag == null ? 'Create Tag' : 'Edit Tag',
            style: AppTextStyles.titleMedium,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _nullableDropdownValue(projectId),
                  dropdownColor: AppColors.bgCard,
                  decoration: const InputDecoration(labelText: 'Project'),
                  items: _projectDirectory
                      .map(
                        (project) => DropdownMenuItem<String>(
                          value: project.id,
                          child: Text(project.name),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) => setDialogState(() => projectId = value),
                ),
                const SizedBox(height: AppSpacing.md),
                MechaTextField(
                  label: 'NAME',
                  hint: 'Tag name',
                  controller: nameController,
                ),
                const SizedBox(height: AppSpacing.md),
                MechaTextField(
                  label: 'COLOR',
                  hint: '#7dd3fc',
                  controller: colorController,
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: _nullableDropdownValue(creatorUserId),
                  dropdownColor: AppColors.bgCard,
                  decoration: const InputDecoration(labelText: 'Creator'),
                  items: _userDirectory
                      .map(
                        (user) => DropdownMenuItem<String>(
                          value: user.id,
                          child: Text(user.resolvedDisplayName),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) =>
                      setDialogState(() => creatorUserId = value),
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
                tag == null ? 'CREATE' : 'SAVE',
                style: const TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || projectId == null) {
      return;
    }

    try {
      if (tag == null) {
        await _adminService.createTag(
          projectId: projectId!,
          name: nameController.text.trim(),
          color: colorController.text.trim(),
          createdByUserId: creatorUserId,
        );
        _showMessage('Tag created.', isError: false);
      } else {
        await _adminService.updateTag(
          tag.id,
          projectId: projectId,
          name: nameController.text.trim(),
          color: colorController.text.trim(),
          createdByUserId: creatorUserId,
        );
        _showMessage('Tag updated.', isError: false);
      }
      await _loadTags();
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('Tag save failed: $error');
    }
  }

  Future<void> _showTagDetailDialog(ProjectTag tag) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: Text(tag.name, style: AppTextStyles.titleMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${tag.project?.name ?? tag.projectId} · ${tag.color}',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            if (tag.creator != null)
              _AdminMetaBadge(
                label:
                    'CREATOR ${tag.creator!.resolvedDisplayName.toUpperCase()}',
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditTagDialog(tag);
            },
            child: const Text(
              'EDIT',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTag(ProjectTag tag) async {
    final confirmed = await _confirmAction(
      title: 'Delete ${tag.name}?',
      message:
          'This removes the tag from the system and detaches it from tasks.',
    );
    if (!confirmed) {
      return;
    }

    setState(() => _busyId = tag.id);
    try {
      await _adminService.deleteTag(tag.id);
      _showMessage('Tag deleted.', isError: false);
      await _loadTags();
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('Delete failed: $error');
    } finally {
      if (mounted) {
        setState(() => _busyId = null);
      }
    }
  }

  Widget _buildFilesSection() {
    return _buildSectionShell(
      filters: _buildFilterPanel(
        tabIndex: 4,
        title: 'Files',
        summary: _fileFiltersSummary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              onChanged: (value) => setState(() => _fileQuery = value),
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Search file name or mime type',
                suffixIcon: IconButton(
                  onPressed: _loadingFiles ? null : _loadFiles,
                  icon: const Icon(Icons.search, color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String?>(
                    initialValue: _fileKind,
                    dropdownColor: AppColors.bgCard,
                    decoration: const InputDecoration(labelText: 'Kind'),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('ALL')),
                      DropdownMenuItem(value: 'image', child: Text('IMAGE')),
                      DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                      DropdownMenuItem(value: 'doc', child: Text('DOC')),
                      DropdownMenuItem(value: 'docx', child: Text('DOCX')),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() => _fileKind = value);
                      _loadFiles();
                    },
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String>(
                    initialValue: _fileOwnerType,
                    dropdownColor: AppColors.bgCard,
                    decoration: const InputDecoration(labelText: 'Owner Type'),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('ALL')),
                      DropdownMenuItem(
                          value: 'unassigned', child: Text('UNASSIGNED')),
                      DropdownMenuItem(
                          value: 'project', child: Text('PROJECT')),
                      DropdownMenuItem(value: 'task', child: Text('TASK')),
                      DropdownMenuItem(value: 'user', child: Text('USER')),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() => _fileOwnerType = value);
                      _loadFiles();
                    },
                  ),
                ),
                SizedBox(
                  width: 240,
                  child: DropdownButtonFormField<String?>(
                    initialValue: _nullableDropdownValue(_fileUploaderId),
                    dropdownColor: AppColors.bgCard,
                    decoration: const InputDecoration(labelText: 'Uploader'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('ALL UPLOADERS'),
                      ),
                      ..._userDirectory.map(
                        (user) => DropdownMenuItem<String?>(
                          value: user.id,
                          child: Text(user.resolvedDisplayName),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _fileUploaderId = value);
                      _loadFiles();
                    },
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: MechaButton(
                    label: 'UPLOAD FILE',
                    onTap: _uploadAdminFile,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      list: _loadingFiles
          ? const Center(child: CircularProgressIndicator())
          : _files.isEmpty
              ? const WorkspaceEmptyState(
                  icon: Icons.folder_open_outlined,
                  title: 'No Files Found',
                  message:
                      'Adjust the filters or upload a file from the admin console.',
                )
              : ListView.separated(
                  itemCount: _files.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final file = _files[index];
                    final isBusy = _busyId == file.id;

                    return MechaPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(file.originalName,
                              style: AppTextStyles.titleMedium),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${file.kind.toUpperCase()} · ${file.uploader?.resolvedDisplayName ?? file.uploadedBy ?? 'unknown'}',
                            style: AppTextStyles.bodySmall,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          ResponsiveActionGroup(
                            breakpoint: 760,
                            children: [
                              MechaButton(
                                label: 'DETAIL',
                                variant: MechaButtonVariant.outlined,
                                onTap: () => _showFileDetailDialog(file),
                              ),
                              MechaButton(
                                label: isBusy ? '...' : 'DELETE',
                                onTap: isBusy ? null : () => _deleteFile(file),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildRemindersSection() {
    return _buildSectionShell(
      filters: _buildFilterPanel(
        tabIndex: 5,
        title: 'Reminders',
        summary: _reminderFiltersSummary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              onChanged: (value) => setState(() => _reminderQuery = value),
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Search reminder message',
                suffixIcon: IconButton(
                  onPressed: _loadingReminders ? null : _loadReminders,
                  icon: const Icon(Icons.search, color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                SizedBox(
                  width: 240,
                  child: DropdownButtonFormField<String?>(
                    initialValue: _nullableDropdownValue(_reminderUserId),
                    dropdownColor: AppColors.bgCard,
                    decoration: const InputDecoration(labelText: 'User'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('ALL USERS'),
                      ),
                      ..._userDirectory.map(
                        (user) => DropdownMenuItem<String?>(
                          value: user.id,
                          child: Text(user.resolvedDisplayName),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _reminderUserId = value);
                      _loadReminders();
                    },
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String>(
                    initialValue: _reminderCompleted,
                    dropdownColor: AppColors.bgCard,
                    decoration: const InputDecoration(labelText: 'Completion'),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('ALL')),
                      DropdownMenuItem(value: 'open', child: Text('OPEN')),
                      DropdownMenuItem(value: 'done', child: Text('DONE')),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() => _reminderCompleted = value);
                      _loadReminders();
                    },
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: MechaButton(
                    label: 'CREATE REMINDER',
                    onTap: _showCreateReminderDialog,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      list: _loadingReminders
          ? const Center(child: CircularProgressIndicator())
          : _reminders.isEmpty
              ? const WorkspaceEmptyState(
                  icon: Icons.alarm_outlined,
                  title: 'No Reminders Found',
                  message:
                      'Adjust the filters or create a reminder from the admin console.',
                )
              : ListView.separated(
                  itemCount: _reminders.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final reminder = _reminders[index];
                    final isBusy = _busyId == reminder.id;

                    return MechaPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(reminder.message,
                              style: AppTextStyles.titleMedium),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${reminder.user?.resolvedDisplayName ?? reminder.userId} · ${formatShortDateTime(reminder.scheduledTime)}',
                            style: AppTextStyles.bodySmall,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          ResponsiveActionGroup(
                            breakpoint: 760,
                            children: [
                              MechaButton(
                                label: 'DETAIL',
                                variant: MechaButtonVariant.outlined,
                                onTap: () =>
                                    _showReminderDetailDialog(reminder),
                              ),
                              MechaButton(
                                label: isBusy ? '...' : 'DELETE',
                                onTap: isBusy
                                    ? null
                                    : () => _deleteReminder(reminder),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Future<void> _uploadAdminFile() async {
    final picked = await FilePicker.platform.pickFiles(allowMultiple: false);
    if (picked == null || picked.files.isEmpty) {
      return;
    }

    final path = picked.files.single.path;
    if (path == null || path.isEmpty) {
      return;
    }

    if (!mounted) {
      return;
    }

    String? uploaderId =
        _userDirectory.isNotEmpty ? _userDirectory.first.id : null;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          title: Text('Upload File', style: AppTextStyles.titleMedium),
          content: DropdownButtonFormField<String>(
            initialValue: _nullableDropdownValue(uploaderId),
            dropdownColor: AppColors.bgCard,
            decoration: const InputDecoration(labelText: 'Uploader'),
            items: _userDirectory
                .map(
                  (user) => DropdownMenuItem<String>(
                    value: user.id,
                    child: Text(user.resolvedDisplayName),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) => setDialogState(() => uploaderId = value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'UPLOAD',
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

    try {
      await _adminService.uploadFile(
        filePath: path,
        uploadedByUserId: uploaderId,
      );
      _showMessage('File uploaded.', isError: false);
      await _loadFiles();
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('Upload failed: $error');
    }
  }

  Future<void> _showFileDetailDialog(FileAsset file) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: Text(file.originalName, style: AppTextStyles.titleMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${file.kind.toUpperCase()} · ${formatBytes(file.size)}',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Uploader: ${file.uploader?.resolvedDisplayName ?? file.uploadedBy ?? 'unknown'}',
              style: AppTextStyles.bodySmall,
            ),
            if (file.ownerType != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Owner: ${file.ownerType} ${file.ownerProject?.name ?? file.ownerTask?.title ?? file.ownerUser?.resolvedDisplayName ?? file.ownerId ?? ''}',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditFileDialog(file);
            },
            child: const Text(
              'EDIT',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditFileDialog(FileAsset file) async {
    final nameController = TextEditingController(text: file.originalName);
    final ownerIdController = TextEditingController(text: file.ownerId ?? '');
    var ownerType = file.ownerType ?? 'unassigned';
    String? uploaderId = file.uploadedBy;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          title: Text('Edit File', style: AppTextStyles.titleMedium),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MechaTextField(
                  label: 'NAME',
                  hint: 'File name',
                  controller: nameController,
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: ownerType,
                  dropdownColor: AppColors.bgCard,
                  decoration: const InputDecoration(labelText: 'Owner Type'),
                  items: const [
                    DropdownMenuItem(
                        value: 'unassigned', child: Text('UNASSIGNED')),
                    DropdownMenuItem(value: 'project', child: Text('PROJECT')),
                    DropdownMenuItem(value: 'task', child: Text('TASK')),
                    DropdownMenuItem(value: 'user', child: Text('USER')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => ownerType = value);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                MechaTextField(
                  label: 'OWNER ID',
                  hint: 'Leave blank when unassigned',
                  controller: ownerIdController,
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: _nullableDropdownValue(uploaderId),
                  dropdownColor: AppColors.bgCard,
                  decoration: const InputDecoration(labelText: 'Uploader'),
                  items: _userDirectory
                      .map(
                        (user) => DropdownMenuItem<String>(
                          value: user.id,
                          child: Text(user.resolvedDisplayName),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) =>
                      setDialogState(() => uploaderId = value),
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

    try {
      await _adminService.updateFile(
        file.id,
        originalName: nameController.text.trim(),
        ownerType: ownerType,
        ownerId: ownerIdController.text.trim(),
        uploadedByUserId: uploaderId,
      );
      _showMessage('File updated.', isError: false);
      await _loadFiles();
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('File update failed: $error');
    }
  }

  Future<void> _deleteFile(FileAsset file) async {
    final confirmed = await _confirmAction(
      title: 'Delete ${file.originalName}?',
      message: 'This removes the file from storage and the database.',
    );
    if (!confirmed) {
      return;
    }

    setState(() => _busyId = file.id);
    try {
      await _adminService.deleteFile(file.id);
      _showMessage('File deleted.', isError: false);
      await _loadFiles();
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('Delete failed: $error');
    } finally {
      if (mounted) {
        setState(() => _busyId = null);
      }
    }
  }

  Future<void> _showCreateReminderDialog() async {
    await _showReminderEditor();
  }

  Future<void> _showEditReminderDialog(ReminderEntry reminder) async {
    await _showReminderEditor(reminder: reminder);
  }

  Future<void> _showReminderEditor({ReminderEntry? reminder}) async {
    String? userId = reminder?.userId ??
        _reminderUserId ??
        (_userDirectory.isNotEmpty ? _userDirectory.first.id : null);
    final messageController =
        TextEditingController(text: reminder?.message ?? '');
    var scheduledTime = reminder?.scheduledTime;
    var isCompleted = reminder?.isCompleted ?? false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          title: Text(
            reminder == null ? 'Create Reminder' : 'Edit Reminder',
            style: AppTextStyles.titleMedium,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _nullableDropdownValue(userId),
                  dropdownColor: AppColors.bgCard,
                  decoration: const InputDecoration(labelText: 'User'),
                  items: _userDirectory
                      .map(
                        (user) => DropdownMenuItem<String>(
                          value: user.id,
                          child: Text(user.resolvedDisplayName),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) => setDialogState(() => userId = value),
                ),
                const SizedBox(height: AppSpacing.md),
                MechaTextField(
                  label: 'MESSAGE',
                  hint: 'Reminder message',
                  controller: messageController,
                ),
                const SizedBox(height: AppSpacing.md),
                MechaButton(
                  label: scheduledTime == null
                      ? 'SET SCHEDULE'
                      : formatShortDateTime(scheduledTime),
                  variant: MechaButtonVariant.outlined,
                  onTap: () async {
                    final picked =
                        await _pickDateTime(initialValue: scheduledTime);
                    if (picked != null) {
                      setDialogState(() => scheduledTime = picked);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                SwitchListTile(
                  value: isCompleted,
                  onChanged: (value) =>
                      setDialogState(() => isCompleted = value),
                  title: const Text('Completed'),
                  contentPadding: EdgeInsets.zero,
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
                reminder == null ? 'CREATE' : 'SAVE',
                style: const TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || userId == null || scheduledTime == null) {
      return;
    }

    try {
      if (reminder == null) {
        await _adminService.createReminder(
          userId: userId!,
          message: messageController.text.trim(),
          scheduledTime: scheduledTime!,
        );
        _showMessage('Reminder created.', isError: false);
      } else {
        await _adminService.updateReminder(
          reminder.id,
          userId: userId,
          message: messageController.text.trim(),
          scheduledTime: scheduledTime,
          isCompleted: isCompleted,
        );
        _showMessage('Reminder updated.', isError: false);
      }
      await _loadReminders();
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('Reminder save failed: $error');
    }
  }

  Future<void> _showReminderDetailDialog(ReminderEntry reminder) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: Text(reminder.message, style: AppTextStyles.titleMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${reminder.user?.resolvedDisplayName ?? reminder.userId} · ${formatShortDateTime(reminder.scheduledTime)}',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            _AdminMetaBadge(
              label: reminder.isCompleted ? 'DONE' : 'OPEN',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditReminderDialog(reminder);
            },
            child: const Text(
              'EDIT',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteReminder(ReminderEntry reminder) async {
    final confirmed = await _confirmAction(
      title: 'Delete reminder?',
      message: 'This removes the reminder from the system.',
    );
    if (!confirmed) {
      return;
    }

    setState(() => _busyId = reminder.id);
    try {
      await _adminService.deleteReminder(reminder.id);
      _showMessage('Reminder deleted.', isError: false);
      await _loadReminders();
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('Delete failed: $error');
    } finally {
      if (mounted) {
        setState(() => _busyId = null);
      }
    }
  }
}

class _AdminMetaBadge extends StatelessWidget {
  const _AdminMetaBadge({required this.label});

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
