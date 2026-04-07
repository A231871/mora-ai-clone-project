import '../../../core/services/api_client.dart';
import '../../../shared/models/workspace_models.dart';

class TasksService {
  TasksService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  Future<List<TaskItem>> listTasks({
    String? projectId,
    String? status,
    String? priority,
    String? tagId,
    String? assigneeId,
  }) async {
    final rawTasks = await _apiClient.get(
      '/tasks',
      queryParameters: <String, String?>{
        'projectId': projectId,
        'status': status,
        'priority': priority,
        'tagId': tagId,
        'assigneeId': assigneeId,
      },
    ) as List<dynamic>;

    return rawTasks.map(TaskItem.fromJson).toList(growable: false);
  }

  Future<TaskItem> getTask(String taskId) async {
    final rawTask = await _apiClient.get('/tasks/$taskId');
    return TaskItem.fromJson(rawTask);
  }

  Future<TaskItem> createTask({
    required String projectId,
    required String title,
    String description = '',
    String status = 'todo',
    String priority = 'medium',
    DateTime? dueDate,
    int? estimatedMinutes,
    List<String> assigneeIds = const <String>[],
    List<String> tagIds = const <String>[],
    List<String> fileIds = const <String>[],
    DateTime? reminderAt,
  }) async {
    final rawTask = await _apiClient.post(
      '/tasks',
      body: <String, dynamic>{
        'projectId': projectId,
        'title': title,
        'description': description,
        'status': status,
        'priority': priority,
        if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
        if (estimatedMinutes != null) 'estimatedMinutes': estimatedMinutes,
        'assigneeIds': assigneeIds,
        'tagIds': tagIds,
        'fileIds': fileIds,
        if (reminderAt != null) 'reminderAt': reminderAt.toIso8601String(),
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
    DateTime? dueDate,
    int? estimatedMinutes,
    List<String>? assigneeIds,
    List<String>? tagIds,
    List<String>? fileIds,
    DateTime? reminderAt,
    bool clearReminder = false,
    bool clearDueDate = false,
    bool clearEstimatedMinutes = false,
  }) async {
    final rawTask = await _apiClient.patch(
      '/tasks/$taskId',
      body: <String, dynamic>{
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (status != null) 'status': status,
        if (priority != null) 'priority': priority,
        if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
        if (clearDueDate) 'dueDate': null,
        if (estimatedMinutes != null) 'estimatedMinutes': estimatedMinutes,
        if (clearEstimatedMinutes) 'estimatedMinutes': null,
        if (assigneeIds != null) 'assigneeIds': assigneeIds,
        if (tagIds != null) 'tagIds': tagIds,
        if (fileIds != null) 'fileIds': fileIds,
        if (reminderAt != null) 'reminderAt': reminderAt.toIso8601String(),
        if (clearReminder) 'reminderAt': null,
      },
    );

    return TaskItem.fromJson(rawTask);
  }

  Future<void> deleteTask(String taskId) async {
    await _apiClient.delete('/tasks/$taskId');
  }

  Future<List<TaskComment>> listComments(String taskId) async {
    final rawComments =
        await _apiClient.get('/tasks/$taskId/comments') as List<dynamic>;
    return rawComments.map(TaskComment.fromJson).toList(growable: false);
  }

  Future<TaskComment> createComment(
    String taskId, {
    required String content,
  }) async {
    final rawComment = await _apiClient.post(
      '/tasks/$taskId/comments',
      body: <String, dynamic>{'content': content},
    );

    return TaskComment.fromJson(rawComment);
  }

  Future<TaskComment> updateComment(
    String taskId,
    String commentId, {
    required String content,
  }) async {
    final rawComment = await _apiClient.patch(
      '/tasks/$taskId/comments/$commentId',
      body: <String, dynamic>{'content': content},
    );

    return TaskComment.fromJson(rawComment);
  }

  Future<void> deleteComment(String taskId, String commentId) async {
    await _apiClient.delete('/tasks/$taskId/comments/$commentId');
  }

  Future<List<TaskChecklistEntry>> listChecklist(String taskId) async {
    final rawItems =
        await _apiClient.get('/tasks/$taskId/checklist') as List<dynamic>;
    return rawItems.map(TaskChecklistEntry.fromJson).toList(growable: false);
  }

  Future<TaskChecklistEntry> createChecklistItem(
    String taskId, {
    required String content,
  }) async {
    final rawItem = await _apiClient.post(
      '/tasks/$taskId/checklist',
      body: <String, dynamic>{'content': content},
    );

    return TaskChecklistEntry.fromJson(rawItem);
  }

  Future<TaskChecklistEntry> updateChecklistItem(
    String taskId,
    String itemId, {
    String? content,
    bool? isCompleted,
  }) async {
    final rawItem = await _apiClient.patch(
      '/tasks/$taskId/checklist/$itemId',
      body: <String, dynamic>{
        if (content != null) 'content': content,
        if (isCompleted != null) 'isCompleted': isCompleted,
      },
    );

    return TaskChecklistEntry.fromJson(rawItem);
  }

  Future<void> deleteChecklistItem(String taskId, String itemId) async {
    await _apiClient.delete('/tasks/$taskId/checklist/$itemId');
  }

  Future<List<TaskActivityEntry>> listActivity(String taskId) async {
    final rawItems =
        await _apiClient.get('/tasks/$taskId/activity') as List<dynamic>;
    return rawItems.map(TaskActivityEntry.fromJson).toList(growable: false);
  }
}
