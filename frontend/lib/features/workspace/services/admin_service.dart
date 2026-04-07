import '../../../core/services/api_client.dart';
import '../../../shared/models/workspace_models.dart';

class AdminService {
  AdminService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  Future<List<AppUser>> listUsers({
    String? query,
    String? systemRole,
    String? provider,
  }) async {
    final rawUsers = await _apiClient.get(
      '/admin/users',
      queryParameters: <String, String?>{
        'q': query,
        'systemRole': systemRole,
        'provider': provider,
      },
    ) as List<dynamic>;

    return rawUsers.map(AppUser.fromJson).toList(growable: false);
  }

  Future<AppUser> createUser({
    required String username,
    required String password,
    String? email,
    String systemRole = 'member',
    String? displayName,
    String? bio,
  }) async {
    final rawUser = await _apiClient.post(
      '/admin/users',
      body: <String, dynamic>{
        'username': username,
        'password': password,
        'systemRole': systemRole,
        if (email != null && email.isNotEmpty) 'email': email,
        if (displayName != null) 'displayName': displayName,
        if (bio != null) 'bio': bio,
      },
    );

    return AppUser.fromJson(rawUser);
  }

  Future<AppUser> updateUser(
    String userId, {
    String? username,
    String? password,
    String? email,
    String? systemRole,
    String? displayName,
    String? bio,
  }) async {
    final rawUser = await _apiClient.patch(
      '/admin/users/$userId',
      body: <String, dynamic>{
        if (username != null) 'username': username,
        if (password != null) 'password': password,
        if (email != null) 'email': email,
        if (systemRole != null) 'systemRole': systemRole,
        if (displayName != null) 'displayName': displayName,
        if (bio != null) 'bio': bio,
      },
    );

    return AppUser.fromJson(rawUser);
  }

  Future<void> deleteUser(String userId) async {
    await _apiClient.delete('/admin/users/$userId');
  }

  Future<List<WorkspaceProject>> listProjects({
    String? query,
    String? visibility,
    String? createdByUserId,
    String? ownerUserId,
  }) async {
    final rawProjects = await _apiClient.get(
      '/admin/projects',
      queryParameters: <String, String?>{
        'q': query,
        'visibility': visibility,
        'createdByUserId': createdByUserId,
        'ownerUserId': ownerUserId,
      },
    ) as List<dynamic>;

    return rawProjects.map(WorkspaceProject.fromJson).toList(growable: false);
  }

  Future<WorkspaceProject> createProject({
    required String name,
    String description = '',
    String visibility = 'private',
    String? ownerUserId,
    String? createdByUserId,
  }) async {
    final rawProject = await _apiClient.post(
      '/admin/projects',
      body: <String, dynamic>{
        'name': name,
        'description': description,
        'visibility': visibility,
        if (ownerUserId != null && ownerUserId.isNotEmpty)
          'ownerUserId': ownerUserId,
        if (createdByUserId != null && createdByUserId.isNotEmpty)
          'createdByUserId': createdByUserId,
      },
    );

    return WorkspaceProject.fromJson(rawProject);
  }

  Future<WorkspaceProject> getProject(String projectId) async {
    final rawProject = await _apiClient.get('/admin/projects/$projectId');
    return WorkspaceProject.fromJson(rawProject);
  }

  Future<WorkspaceProject> updateProject(
    String projectId, {
    String? name,
    String? description,
    String? visibility,
    String? createdByUserId,
  }) async {
    final rawProject = await _apiClient.patch(
      '/admin/projects/$projectId',
      body: <String, dynamic>{
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (visibility != null) 'visibility': visibility,
        if (createdByUserId != null) 'createdByUserId': createdByUserId,
      },
    );

    return WorkspaceProject.fromJson(rawProject);
  }

  Future<void> deleteProject(String projectId) async {
    await _apiClient.delete('/admin/projects/$projectId');
  }

  Future<ProjectMember> addProjectMember(
    String projectId, {
    required String userId,
    required String role,
  }) async {
    final rawMember = await _apiClient.post(
      '/admin/projects/$projectId/members',
      body: <String, dynamic>{'userId': userId, 'role': role},
    );

    return ProjectMember.fromJson(rawMember);
  }

  Future<ProjectInvite> createProjectInvite(
    String projectId, {
    String? userId,
    String? username,
    required String role,
  }) async {
    final rawInvite = await _apiClient.post(
      '/admin/projects/$projectId/invites',
      body: <String, dynamic>{
        if (userId != null && userId.isNotEmpty) 'userId': userId,
        if (username != null && username.isNotEmpty) 'username': username,
        'role': role,
      },
    );

    return ProjectInvite.fromJson(rawInvite);
  }

  Future<ProjectMember> updateProjectMember(
    String projectId,
    String memberId, {
    required String role,
  }) async {
    final rawMember = await _apiClient.patch(
      '/admin/projects/$projectId/members/$memberId',
      body: <String, dynamic>{'role': role},
    );

    return ProjectMember.fromJson(rawMember);
  }

  Future<void> deleteProjectMember(String projectId, String memberId) async {
    await _apiClient.delete('/admin/projects/$projectId/members/$memberId');
  }

  Future<void> deleteProjectInvite(String projectId, String inviteId) async {
    await _apiClient.delete('/admin/projects/$projectId/invites/$inviteId');
  }

  Future<List<TaskItem>> listTasks({
    String? query,
    String? projectId,
    String? status,
    String? priority,
    String? assigneeId,
    String? createdByUserId,
  }) async {
    final rawTasks = await _apiClient.get(
      '/admin/tasks',
      queryParameters: <String, String?>{
        'q': query,
        'projectId': projectId,
        'status': status,
        'priority': priority,
        'assigneeId': assigneeId,
        'createdByUserId': createdByUserId,
      },
    ) as List<dynamic>;

    return rawTasks.map(TaskItem.fromJson).toList(growable: false);
  }

  Future<TaskItem> getTask(String taskId) async {
    final rawTask = await _apiClient.get('/admin/tasks/$taskId');
    return TaskItem.fromJson(rawTask);
  }

  Future<TaskItem> createTask({
    required String projectId,
    required String title,
    String description = '',
    String status = 'todo',
    String priority = 'medium',
    List<String> assigneeIds = const <String>[],
    List<String> tagIds = const <String>[],
    List<String> fileIds = const <String>[],
    DateTime? reminderAt,
    String? createdByUserId,
    String? reminderUserId,
  }) async {
    final rawTask = await _apiClient.post(
      '/admin/tasks',
      body: <String, dynamic>{
        'projectId': projectId,
        'title': title,
        'description': description,
        'status': status,
        'priority': priority,
        'assigneeIds': assigneeIds,
        'tagIds': tagIds,
        'fileIds': fileIds,
        if (reminderAt != null) 'reminderAt': reminderAt.toIso8601String(),
        if (createdByUserId != null) 'createdByUserId': createdByUserId,
        if (reminderUserId != null) 'reminderUserId': reminderUserId,
      },
    );

    return TaskItem.fromJson(rawTask);
  }

  Future<TaskItem> updateTask(
    String taskId, {
    String? title,
    String? description,
    String? status,
    String? priority,
    List<String>? assigneeIds,
    List<String>? tagIds,
    List<String>? fileIds,
    DateTime? reminderAt,
    bool clearReminder = false,
    String? createdByUserId,
    String? reminderUserId,
  }) async {
    final rawTask = await _apiClient.patch(
      '/admin/tasks/$taskId',
      body: <String, dynamic>{
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (status != null) 'status': status,
        if (priority != null) 'priority': priority,
        if (assigneeIds != null) 'assigneeIds': assigneeIds,
        if (tagIds != null) 'tagIds': tagIds,
        if (fileIds != null) 'fileIds': fileIds,
        if (reminderAt != null) 'reminderAt': reminderAt.toIso8601String(),
        if (clearReminder) 'reminderAt': null,
        if (createdByUserId != null) 'createdByUserId': createdByUserId,
        if (reminderUserId != null) 'reminderUserId': reminderUserId,
      },
    );

    return TaskItem.fromJson(rawTask);
  }

  Future<void> deleteTask(String taskId) async {
    await _apiClient.delete('/admin/tasks/$taskId');
  }

  Future<List<ProjectTag>> listTags({
    String? query,
    String? projectId,
    String? createdByUserId,
  }) async {
    final rawTags = await _apiClient.get(
      '/admin/tags',
      queryParameters: <String, String?>{
        'q': query,
        'projectId': projectId,
        'createdByUserId': createdByUserId,
      },
    ) as List<dynamic>;

    return rawTags.map(ProjectTag.fromJson).toList(growable: false);
  }

  Future<ProjectTag> createTag({
    required String projectId,
    required String name,
    required String color,
    String? createdByUserId,
  }) async {
    final rawTag = await _apiClient.post(
      '/admin/tags',
      body: <String, dynamic>{
        'projectId': projectId,
        'name': name,
        'color': color,
        if (createdByUserId != null) 'createdByUserId': createdByUserId,
      },
    );

    return ProjectTag.fromJson(rawTag);
  }

  Future<ProjectTag> updateTag(
    String tagId, {
    String? projectId,
    String? name,
    String? color,
    String? createdByUserId,
  }) async {
    final rawTag = await _apiClient.patch(
      '/admin/tags/$tagId',
      body: <String, dynamic>{
        if (projectId != null) 'projectId': projectId,
        if (name != null) 'name': name,
        if (color != null) 'color': color,
        if (createdByUserId != null) 'createdByUserId': createdByUserId,
      },
    );

    return ProjectTag.fromJson(rawTag);
  }

  Future<void> deleteTag(String tagId) async {
    await _apiClient.delete('/admin/tags/$tagId');
  }

  Future<List<FileAsset>> listFiles({
    String? query,
    String? ownerType,
    String? ownerId,
    String? kind,
    String? uploadedByUserId,
  }) async {
    final rawFiles = await _apiClient.get(
      '/admin/files',
      queryParameters: <String, String?>{
        'q': query,
        'ownerType': ownerType,
        'ownerId': ownerId,
        'kind': kind,
        'uploadedByUserId': uploadedByUserId,
      },
    ) as List<dynamic>;

    return rawFiles.map(FileAsset.fromJson).toList(growable: false);
  }

  Future<FileAsset> getFile(String fileId) async {
    final rawFile = await _apiClient.get('/admin/files/$fileId');
    return FileAsset.fromJson(rawFile);
  }

  Future<FileAsset> uploadFile({
    required String filePath,
    String ownerType = 'unassigned',
    String? ownerId,
    String? uploadedByUserId,
  }) async {
    final rawFile = await _apiClient.postMultipart(
      '/admin/files',
      filePath: filePath,
      fields: <String, String>{
        'ownerType': ownerType,
        if (ownerId != null && ownerId.isNotEmpty) 'ownerId': ownerId,
        if (uploadedByUserId != null && uploadedByUserId.isNotEmpty)
          'uploadedByUserId': uploadedByUserId,
      },
    );

    return FileAsset.fromJson(rawFile);
  }

  Future<FileAsset> updateFile(
    String fileId, {
    String? originalName,
    String? ownerType,
    String? ownerId,
    String? uploadedByUserId,
  }) async {
    final rawFile = await _apiClient.patch(
      '/admin/files/$fileId',
      body: <String, dynamic>{
        if (originalName != null) 'originalName': originalName,
        if (ownerType != null) 'ownerType': ownerType,
        if (ownerId != null) 'ownerId': ownerId,
        if (uploadedByUserId != null) 'uploadedByUserId': uploadedByUserId,
      },
    );

    return FileAsset.fromJson(rawFile);
  }

  Future<void> deleteFile(String fileId) async {
    await _apiClient.delete('/admin/files/$fileId');
  }

  Future<List<ReminderEntry>> listReminders({
    String? query,
    String? userId,
    String? projectId,
    String? taskId,
    bool? isCompleted,
  }) async {
    final rawReminders = await _apiClient.get(
      '/admin/reminders',
      queryParameters: <String, String?>{
        'q': query,
        'userId': userId,
        'projectId': projectId,
        'taskId': taskId,
        if (isCompleted != null) 'isCompleted': '$isCompleted',
      },
    ) as List<dynamic>;

    return rawReminders.map(ReminderEntry.fromJson).toList(growable: false);
  }

  Future<ReminderEntry> createReminder({
    required String userId,
    required String message,
    required DateTime scheduledTime,
    String? projectId,
    String? taskId,
    List<String> daysOfWeek = const <String>[],
  }) async {
    final rawReminder = await _apiClient.post(
      '/admin/reminders',
      body: <String, dynamic>{
        'userId': userId,
        'message': message,
        'scheduledTime': scheduledTime.toIso8601String(),
        'daysOfWeek': daysOfWeek,
        if (projectId != null) 'projectId': projectId,
        if (taskId != null) 'taskId': taskId,
      },
    );

    return ReminderEntry.fromJson(rawReminder);
  }

  Future<ReminderEntry> updateReminder(
    String reminderId, {
    String? userId,
    String? message,
    DateTime? scheduledTime,
    String? projectId,
    String? taskId,
    List<String>? daysOfWeek,
    bool? isCompleted,
  }) async {
    final rawReminder = await _apiClient.patch(
      '/admin/reminders/$reminderId',
      body: <String, dynamic>{
        if (userId != null) 'userId': userId,
        if (message != null) 'message': message,
        if (scheduledTime != null)
          'scheduledTime': scheduledTime.toIso8601String(),
        if (projectId != null) 'projectId': projectId,
        if (taskId != null) 'taskId': taskId,
        if (daysOfWeek != null) 'daysOfWeek': daysOfWeek,
        if (isCompleted != null) 'isCompleted': isCompleted,
      },
    );

    return ReminderEntry.fromJson(rawReminder);
  }

  Future<void> deleteReminder(String reminderId) async {
    await _apiClient.delete('/admin/reminders/$reminderId');
  }
}
