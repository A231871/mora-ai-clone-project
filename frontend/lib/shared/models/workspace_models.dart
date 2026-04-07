import 'dart:convert';

Map<String, dynamic> asJsonMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  if (value is String && value.isNotEmpty) {
    final trimmed = value.trimLeft();
    if (trimmed.startsWith('{')) {
      final decoded = jsonDecode(value);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    }
  }
  return <String, dynamic>{};
}

List<Map<String, dynamic>> asJsonList(dynamic value) {
  if (value is! Iterable) {
    return const <Map<String, dynamic>>[];
  }

  return value
      .map((item) => asJsonMap(item))
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

String readJsonId(dynamic value) {
  if (value is String) {
    return value;
  }

  final map = asJsonMap(value);
  return (map['_id'] ?? map['id'] ?? '').toString();
}

String? readNullableString(dynamic value) {
  if (value == null) {
    return null;
  }
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

DateTime? parseDateTime(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  return DateTime.tryParse(value.toString());
}

bool parseBool(dynamic value) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }
  return false;
}

class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.systemRole,
    this.email,
    this.googleId,
    this.authProvider,
    this.displayName,
    this.bio,
    this.avatarConfig = const <String, dynamic>{},
    this.avatarAssetId,
    this.lastLoginAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String username;
  final String systemRole;
  final String? email;
  final String? googleId;
  final String? authProvider;
  final String? displayName;
  final String? bio;
  final Map<String, dynamic> avatarConfig;
  final String? avatarAssetId;
  final DateTime? lastLoginAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get resolvedDisplayName => readNullableString(displayName) ?? username;

  bool get isAdmin => systemRole == 'admin';

  factory AppUser.fromJson(dynamic rawJson) {
    final json = asJsonMap(rawJson);
    final profile = asJsonMap(json['profile']);

    return AppUser(
      id: readJsonId(json),
      username: (json['username'] ?? 'unknown').toString(),
      systemRole: (json['systemRole'] ?? 'member').toString(),
      email: readNullableString(json['email']),
      googleId: readNullableString(json['googleId']),
      authProvider: readNullableString(json['authProvider']),
      displayName: readNullableString(profile['displayName']),
      bio: readNullableString(profile['bio']),
      avatarConfig: asJsonMap(json['avatarConfig']),
      avatarAssetId: readNullableString(json['avatarAssetId']),
      lastLoginAt: parseDateTime(json['lastLoginAt']),
      createdAt: parseDateTime(json['createdAt']),
      updatedAt: parseDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'username': username,
      'email': email,
      'googleId': googleId,
      'authProvider': authProvider,
      'systemRole': systemRole,
      'profile': <String, dynamic>{
        'displayName': displayName ?? '',
        'bio': bio ?? '',
      },
      'avatarConfig': avatarConfig,
      'avatarAssetId': avatarAssetId,
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class FileAsset {
  const FileAsset({
    required this.id,
    required this.kind,
    required this.originalName,
    required this.publicUrl,
    this.attachedTaskIds = const <String>[],
    this.ownerType,
    this.ownerId,
    this.uploadedBy,
    this.mimeType,
    this.size,
    this.attachedAt,
    this.uploader,
    this.ownerUser,
    this.ownerProject,
    this.ownerTask,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String kind;
  final String originalName;
  final String publicUrl;
  final List<String> attachedTaskIds;
  final String? ownerType;
  final String? ownerId;
  final String? uploadedBy;
  final String? mimeType;
  final int? size;
  final DateTime? attachedAt;
  final AppUser? uploader;
  final AppUser? ownerUser;
  final WorkspaceProject? ownerProject;
  final TaskItem? ownerTask;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isImage => kind == 'image';
  bool get hasTaskAttachments => attachedTaskIds.isNotEmpty;
  int get attachedTaskCount => attachedTaskIds.length;

  factory FileAsset.fromJson(dynamic rawJson) {
    final json = asJsonMap(rawJson);
    final uploaderJson = asJsonMap(json['uploadedBy']);
    final ownerUserJson = asJsonMap(json['ownerUser']);
    final ownerProjectJson = asJsonMap(json['ownerProject']);
    final ownerTaskJson = asJsonMap(json['ownerTask']);
    return FileAsset(
      id: readJsonId(json),
      kind: (json['kind'] ?? 'image').toString(),
      originalName: (json['originalName'] ?? 'Untitled').toString(),
      publicUrl: (json['publicUrl'] ?? '').toString(),
      attachedTaskIds: (json['taskIds'] is Iterable)
          ? (json['taskIds'] as Iterable)
              .map(readJsonId)
              .where((value) => value.isNotEmpty)
              .toList(growable: false)
          : const <String>[],
      ownerType: readNullableString(json['ownerType']),
      ownerId: readNullableString(json['ownerId']),
      uploadedBy: readJsonId(json['uploadedBy']),
      mimeType: readNullableString(json['mimeType']),
      size: json['size'] is num ? (json['size'] as num).toInt() : null,
      attachedAt: parseDateTime(json['attachedAt']),
      uploader: uploaderJson.isEmpty ? null : AppUser.fromJson(uploaderJson),
      ownerUser: ownerUserJson.isEmpty ? null : AppUser.fromJson(ownerUserJson),
      ownerProject: ownerProjectJson.isEmpty
          ? null
          : WorkspaceProject.fromJson(ownerProjectJson),
      ownerTask:
          ownerTaskJson.isEmpty ? null : TaskItem.fromJson(ownerTaskJson),
      createdAt: parseDateTime(json['createdAt']),
      updatedAt: parseDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'kind': kind,
      'originalName': originalName,
      'publicUrl': publicUrl,
      'taskIds': attachedTaskIds,
      'ownerType': ownerType,
      'ownerId': ownerId,
      'uploadedBy': uploadedBy,
      'mimeType': mimeType,
      'size': size,
      'attachedAt': attachedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class ProjectTag {
  const ProjectTag({
    required this.id,
    required this.projectId,
    required this.name,
    required this.color,
    this.createdBy,
    this.project,
    this.creator,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String projectId;
  final String name;
  final String color;
  final String? createdBy;
  final WorkspaceProject? project;
  final AppUser? creator;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ProjectTag.fromJson(dynamic rawJson) {
    final json = asJsonMap(rawJson);
    final projectJson = asJsonMap(json['projectId']);
    final creatorJson = asJsonMap(json['createdBy']);
    return ProjectTag(
      id: readJsonId(json),
      projectId: readJsonId(json['projectId']),
      name: (json['name'] ?? 'Tag').toString(),
      color: (json['color'] ?? '#7dd3fc').toString(),
      createdBy: readJsonId(json['createdBy']),
      project:
          projectJson.isEmpty ? null : WorkspaceProject.fromJson(projectJson),
      creator: creatorJson.isEmpty ? null : AppUser.fromJson(creatorJson),
      createdAt: parseDateTime(json['createdAt']),
      updatedAt: parseDateTime(json['updatedAt']),
    );
  }
}

class ProjectMember {
  const ProjectMember({
    required this.id,
    required this.projectId,
    required this.userId,
    required this.role,
    this.user,
    this.createdAt,
  });

  final String id;
  final String projectId;
  final String userId;
  final String role;
  final AppUser? user;
  final DateTime? createdAt;

  factory ProjectMember.fromJson(dynamic rawJson) {
    final json = asJsonMap(rawJson);
    final userJson = asJsonMap(json['userId']);

    return ProjectMember(
      id: readJsonId(json),
      projectId: readJsonId(json['projectId']),
      userId: readJsonId(json['userId']),
      role: (json['role'] ?? 'viewer').toString(),
      user: userJson.isEmpty ? null : AppUser.fromJson(userJson),
      createdAt: parseDateTime(json['createdAt']),
    );
  }
}

class ProjectInvite {
  const ProjectInvite({
    required this.id,
    required this.projectId,
    required this.inviterUserId,
    required this.inviteeUserId,
    required this.role,
    required this.status,
    this.project,
    this.inviter,
    this.invitee,
    this.respondedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String projectId;
  final String inviterUserId;
  final String inviteeUserId;
  final String role;
  final String status;
  final WorkspaceProject? project;
  final AppUser? inviter;
  final AppUser? invitee;
  final DateTime? respondedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isPending => status == 'pending';

  factory ProjectInvite.fromJson(dynamic rawJson) {
    final json = asJsonMap(rawJson);
    final projectJson = asJsonMap(json['projectId']);
    final inviterJson = asJsonMap(json['inviterUserId']);
    final inviteeJson = asJsonMap(json['inviteeUserId']);

    return ProjectInvite(
      id: readJsonId(json),
      projectId: readJsonId(json['projectId']),
      inviterUserId: readJsonId(json['inviterUserId']),
      inviteeUserId: readJsonId(json['inviteeUserId']),
      role: (json['role'] ?? 'viewer').toString(),
      status: (json['status'] ?? 'pending').toString(),
      project:
          projectJson.isEmpty ? null : WorkspaceProject.fromJson(projectJson),
      inviter: inviterJson.isEmpty ? null : AppUser.fromJson(inviterJson),
      invitee: inviteeJson.isEmpty ? null : AppUser.fromJson(inviteeJson),
      respondedAt: parseDateTime(json['respondedAt']),
      createdAt: parseDateTime(json['createdAt']),
      updatedAt: parseDateTime(json['updatedAt']),
    );
  }
}

class WorkspaceProject {
  const WorkspaceProject({
    required this.id,
    required this.name,
    required this.description,
    required this.visibility,
    required this.createdBy,
    this.currentRole,
    this.adminReadOnlyOverride = false,
    this.memberUiReadOnly = false,
    this.createdByUser,
    this.ownerUsers = const <AppUser>[],
    this.members = const <ProjectMember>[],
    this.pendingInvites = const <ProjectInvite>[],
    this.acceptedMemberCount,
    this.pendingInviteCount,
    this.archivedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String description;
  final String visibility;
  final String createdBy;
  final String? currentRole;
  final bool adminReadOnlyOverride;
  final bool memberUiReadOnly;
  final AppUser? createdByUser;
  final List<AppUser> ownerUsers;
  final List<ProjectMember> members;
  final List<ProjectInvite> pendingInvites;
  final int? acceptedMemberCount;
  final int? pendingInviteCount;
  final DateTime? archivedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isShared => visibility == 'shared';
  bool get canEditProjectMetadata =>
      !memberUiReadOnly && currentRole == 'owner';
  bool get canManageMembers => !memberUiReadOnly && currentRole == 'owner';
  bool get canManageContent =>
      !memberUiReadOnly && (currentRole == 'owner' || currentRole == 'editor');
  bool get canComment => !memberUiReadOnly;

  factory WorkspaceProject.fromJson(dynamic rawJson) {
    final json = asJsonMap(rawJson);
    final createdByJson = asJsonMap(json['createdBy']);
    return WorkspaceProject(
      id: readJsonId(json),
      name: (json['name'] ?? 'Untitled Project').toString(),
      description: (json['description'] ?? '').toString(),
      visibility: (json['visibility'] ?? 'private').toString(),
      createdBy: readJsonId(json['createdBy']),
      currentRole: readNullableString(json['currentRole']),
      adminReadOnlyOverride: parseBool(json['adminReadOnlyOverride']),
      memberUiReadOnly: parseBool(json['memberUiReadOnly']),
      createdByUser:
          createdByJson.isEmpty ? null : AppUser.fromJson(createdByJson),
      ownerUsers: asJsonList(json['ownerUsers'])
          .map(AppUser.fromJson)
          .toList(growable: false),
      members: asJsonList(json['members'])
          .map(ProjectMember.fromJson)
          .toList(growable: false),
      pendingInvites: asJsonList(json['pendingInvites'])
          .map(ProjectInvite.fromJson)
          .toList(growable: false),
      acceptedMemberCount: json['acceptedMemberCount'] is num
          ? (json['acceptedMemberCount'] as num).toInt()
          : null,
      pendingInviteCount: json['pendingInviteCount'] is num
          ? (json['pendingInviteCount'] as num).toInt()
          : null,
      archivedAt: parseDateTime(json['archivedAt']),
      createdAt: parseDateTime(json['createdAt']),
      updatedAt: parseDateTime(json['updatedAt']),
    );
  }
}

class ProjectAnalyticsOverview {
  const ProjectAnalyticsOverview({
    required this.projectId,
    required this.total,
    required this.todo,
    required this.inProgress,
    required this.done,
    required this.overdue,
    required this.dueToday,
    required this.completedCount,
    required this.completionRate,
    this.averageCompletionMinutes,
    this.generatedAt,
  });

  final String projectId;
  final int total;
  final int todo;
  final int inProgress;
  final int done;
  final int overdue;
  final int dueToday;
  final int completedCount;
  final double completionRate;
  final double? averageCompletionMinutes;
  final DateTime? generatedAt;

  factory ProjectAnalyticsOverview.fromJson(dynamic rawJson) {
    final json = asJsonMap(rawJson);
    final totals = asJsonMap(json['totals']);
    final completion = asJsonMap(json['completion']);

    return ProjectAnalyticsOverview(
      projectId: readNullableString(json['projectId']) ?? '',
      total: totals['total'] is num ? (totals['total'] as num).toInt() : 0,
      todo: totals['todo'] is num ? (totals['todo'] as num).toInt() : 0,
      inProgress: totals['inProgress'] is num
          ? (totals['inProgress'] as num).toInt()
          : 0,
      done: totals['done'] is num ? (totals['done'] as num).toInt() : 0,
      overdue:
          totals['overdue'] is num ? (totals['overdue'] as num).toInt() : 0,
      dueToday:
          totals['dueToday'] is num ? (totals['dueToday'] as num).toInt() : 0,
      completedCount: completion['completedCount'] is num
          ? (completion['completedCount'] as num).toInt()
          : 0,
      completionRate: completion['completionRate'] is num
          ? (completion['completionRate'] as num).toDouble()
          : 0,
      averageCompletionMinutes: completion['averageCompletionMinutes'] is num
          ? (completion['averageCompletionMinutes'] as num).toDouble()
          : null,
      generatedAt: parseDateTime(json['generatedAt']),
    );
  }
}

class AnalyticsBreakdownItem {
  const AnalyticsBreakdownItem({
    required this.id,
    required this.label,
    required this.taskCount,
    required this.openTaskCount,
    required this.completedTaskCount,
    this.color,
  });

  final String id;
  final String label;
  final int taskCount;
  final int openTaskCount;
  final int completedTaskCount;
  final String? color;

  factory AnalyticsBreakdownItem.fromJson(dynamic rawJson) {
    final json = asJsonMap(rawJson);
    return AnalyticsBreakdownItem(
      id: readNullableString(json['tagId']) ??
          readNullableString(json['assigneeId']) ??
          readNullableString(json['priority']) ??
          readJsonId(json),
      label: readNullableString(json['label']) ??
          readNullableString(json['priority']) ??
          'Unknown',
      taskCount:
          json['taskCount'] is num ? (json['taskCount'] as num).toInt() : 0,
      openTaskCount: json['openTaskCount'] is num
          ? (json['openTaskCount'] as num).toInt()
          : 0,
      completedTaskCount: json['completedTaskCount'] is num
          ? (json['completedTaskCount'] as num).toInt()
          : 0,
      color: readNullableString(json['color']),
    );
  }
}

class ProjectAnalyticsWorkload {
  const ProjectAnalyticsWorkload({
    required this.projectId,
    required this.priorities,
    required this.assignees,
    required this.tags,
    this.generatedAt,
  });

  final String projectId;
  final List<AnalyticsBreakdownItem> priorities;
  final List<AnalyticsBreakdownItem> assignees;
  final List<AnalyticsBreakdownItem> tags;
  final DateTime? generatedAt;

  factory ProjectAnalyticsWorkload.fromJson(dynamic rawJson) {
    final json = asJsonMap(rawJson);
    return ProjectAnalyticsWorkload(
      projectId: readNullableString(json['projectId']) ?? '',
      priorities: asJsonList(json['priorities'])
          .map(AnalyticsBreakdownItem.fromJson)
          .toList(growable: false),
      assignees: asJsonList(json['assignees'])
          .map(AnalyticsBreakdownItem.fromJson)
          .toList(growable: false),
      tags: asJsonList(json['tags'])
          .map(AnalyticsBreakdownItem.fromJson)
          .toList(growable: false),
      generatedAt: parseDateTime(json['generatedAt']),
    );
  }
}

class TaskItem {
  const TaskItem({
    required this.id,
    required this.projectId,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.assigneeIds,
    required this.tagIds,
    required this.fileIds,
    this.assignees = const <AppUser>[],
    this.tags = const <ProjectTag>[],
    this.files = const <FileAsset>[],
    this.dueDate,
    this.estimatedMinutes,
    this.startedAt,
    this.completedAt,
    this.reminderAt,
    this.reminderId,
    this.createdBy,
    this.updatedBy,
    this.project,
    this.creator,
    this.updater,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String projectId;
  final String title;
  final String description;
  final String status;
  final String priority;
  final List<String> assigneeIds;
  final List<String> tagIds;
  final List<String> fileIds;
  final List<AppUser> assignees;
  final List<ProjectTag> tags;
  final List<FileAsset> files;
  final DateTime? dueDate;
  final int? estimatedMinutes;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? reminderAt;
  final String? reminderId;
  final String? createdBy;
  final String? updatedBy;
  final WorkspaceProject? project;
  final AppUser? creator;
  final AppUser? updater;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isDone => status == 'done';
  bool get isOverdue =>
      !isDone && dueDate != null && dueDate!.isBefore(DateTime.now());

  factory TaskItem.fromJson(dynamic rawJson) {
    final json = asJsonMap(rawJson);
    final assigneesJson = asJsonList(json['assigneeIds']);
    final tagsJson = asJsonList(json['tagIds']);
    final filesJson = asJsonList(json['fileIds']);
    final projectJson = asJsonMap(json['projectId']);
    final creatorJson = asJsonMap(json['createdBy']);
    final updaterJson = asJsonMap(json['updatedBy']);

    return TaskItem(
      id: readJsonId(json),
      projectId: readJsonId(json['projectId']),
      title: (json['title'] ?? 'Untitled Task').toString(),
      description: (json['description'] ?? '').toString(),
      status: (json['status'] ?? 'todo').toString(),
      priority: (json['priority'] ?? 'medium').toString(),
      assigneeIds: (json['assigneeIds'] is Iterable)
          ? (json['assigneeIds'] as Iterable)
              .map(readJsonId)
              .where((value) => value.isNotEmpty)
              .toList(growable: false)
          : const <String>[],
      tagIds: (json['tagIds'] is Iterable)
          ? (json['tagIds'] as Iterable)
              .map(readJsonId)
              .where((value) => value.isNotEmpty)
              .toList(growable: false)
          : const <String>[],
      fileIds: (json['fileIds'] is Iterable)
          ? (json['fileIds'] as Iterable)
              .map(readJsonId)
              .where((value) => value.isNotEmpty)
              .toList(growable: false)
          : const <String>[],
      assignees: assigneesJson.map(AppUser.fromJson).toList(growable: false),
      tags: tagsJson.map(ProjectTag.fromJson).toList(growable: false),
      files: filesJson.map(FileAsset.fromJson).toList(growable: false),
      dueDate: parseDateTime(json['dueDate']),
      estimatedMinutes: json['estimatedMinutes'] is num
          ? (json['estimatedMinutes'] as num).toInt()
          : null,
      startedAt: parseDateTime(json['startedAt']),
      completedAt: parseDateTime(json['completedAt']),
      reminderAt: parseDateTime(json['reminderAt']),
      reminderId: readNullableString(json['reminderId']),
      createdBy: readJsonId(json['createdBy']),
      updatedBy: readJsonId(json['updatedBy']),
      project:
          projectJson.isEmpty ? null : WorkspaceProject.fromJson(projectJson),
      creator: creatorJson.isEmpty ? null : AppUser.fromJson(creatorJson),
      updater: updaterJson.isEmpty ? null : AppUser.fromJson(updaterJson),
      createdAt: parseDateTime(json['createdAt']),
      updatedAt: parseDateTime(json['updatedAt']),
    );
  }
}

class TaskChecklistEntry {
  const TaskChecklistEntry({
    required this.id,
    required this.taskId,
    required this.projectId,
    required this.content,
    required this.isCompleted,
    required this.createdBy,
    required this.updatedBy,
    this.creator,
    this.updater,
    this.completedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String taskId;
  final String projectId;
  final String content;
  final bool isCompleted;
  final String createdBy;
  final String updatedBy;
  final AppUser? creator;
  final AppUser? updater;
  final DateTime? completedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory TaskChecklistEntry.fromJson(dynamic rawJson) {
    final json = asJsonMap(rawJson);
    final createdByJson = asJsonMap(json['createdBy']);
    final updatedByJson = asJsonMap(json['updatedBy']);

    return TaskChecklistEntry(
      id: readJsonId(json),
      taskId: readJsonId(json['taskId']),
      projectId: readJsonId(json['projectId']),
      content: (json['content'] ?? '').toString(),
      isCompleted: parseBool(json['isCompleted']),
      createdBy: readJsonId(json['createdBy']),
      updatedBy: readJsonId(json['updatedBy']),
      creator: createdByJson.isEmpty ? null : AppUser.fromJson(createdByJson),
      updater: updatedByJson.isEmpty ? null : AppUser.fromJson(updatedByJson),
      completedAt: parseDateTime(json['completedAt']),
      createdAt: parseDateTime(json['createdAt']),
      updatedAt: parseDateTime(json['updatedAt']),
    );
  }
}

class TaskActivityEntry {
  const TaskActivityEntry({
    required this.id,
    required this.taskId,
    required this.projectId,
    required this.actorId,
    required this.type,
    required this.message,
    required this.meta,
    this.actor,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String taskId;
  final String projectId;
  final String actorId;
  final String type;
  final String message;
  final Map<String, dynamic> meta;
  final AppUser? actor;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory TaskActivityEntry.fromJson(dynamic rawJson) {
    final json = asJsonMap(rawJson);
    final actorJson = asJsonMap(json['actorId']);

    return TaskActivityEntry(
      id: readJsonId(json),
      taskId: readJsonId(json['taskId']),
      projectId: readJsonId(json['projectId']),
      actorId: readJsonId(json['actorId']),
      type: (json['type'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      meta: asJsonMap(json['meta']),
      actor: actorJson.isEmpty ? null : AppUser.fromJson(actorJson),
      createdAt: parseDateTime(json['createdAt']),
      updatedAt: parseDateTime(json['updatedAt']),
    );
  }
}

class TaskComment {
  const TaskComment({
    required this.id,
    required this.projectId,
    required this.taskId,
    required this.authorId,
    required this.content,
    this.author,
    this.editedAt,
    this.createdAt,
  });

  final String id;
  final String projectId;
  final String taskId;
  final String authorId;
  final String content;
  final AppUser? author;
  final DateTime? editedAt;
  final DateTime? createdAt;

  factory TaskComment.fromJson(dynamic rawJson) {
    final json = asJsonMap(rawJson);
    final authorJson = asJsonMap(json['authorId']);
    return TaskComment(
      id: readJsonId(json),
      projectId: readJsonId(json['projectId']),
      taskId: readJsonId(json['taskId']),
      authorId: readJsonId(json['authorId']),
      content: (json['content'] ?? '').toString(),
      author: authorJson.isEmpty ? null : AppUser.fromJson(authorJson),
      editedAt: parseDateTime(json['editedAt']),
      createdAt: parseDateTime(json['createdAt']),
    );
  }
}

class ReminderEntry {
  const ReminderEntry({
    required this.id,
    required this.userId,
    required this.message,
    required this.scheduledTime,
    required this.isCompleted,
    required this.daysOfWeek,
    this.projectId,
    this.taskId,
    this.user,
    this.project,
    this.task,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String message;
  final DateTime scheduledTime;
  final bool isCompleted;
  final List<String> daysOfWeek;
  final String? projectId;
  final String? taskId;
  final AppUser? user;
  final WorkspaceProject? project;
  final TaskItem? task;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ReminderEntry.fromJson(dynamic rawJson) {
    final json = asJsonMap(rawJson);
    final userJson = asJsonMap(json['userId']);
    final projectJson = asJsonMap(json['projectId']);
    final taskJson = asJsonMap(json['taskId']);

    return ReminderEntry(
      id: readJsonId(json),
      userId: readJsonId(json['userId']),
      message: (json['message'] ?? '').toString(),
      scheduledTime: parseDateTime(json['scheduledTime']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      isCompleted: parseBool(json['isCompleted']),
      daysOfWeek: (json['daysOfWeek'] is Iterable)
          ? (json['daysOfWeek'] as Iterable)
              .map((value) => value.toString())
              .toList(growable: false)
          : const <String>[],
      projectId: readNullableString(readJsonId(json['projectId'])),
      taskId: readNullableString(readJsonId(json['taskId'])),
      user: userJson.isEmpty ? null : AppUser.fromJson(userJson),
      project:
          projectJson.isEmpty ? null : WorkspaceProject.fromJson(projectJson),
      task: taskJson.isEmpty ? null : TaskItem.fromJson(taskJson),
      createdAt: parseDateTime(json['createdAt']),
      updatedAt: parseDateTime(json['updatedAt']),
    );
  }
}
