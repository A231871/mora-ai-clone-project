import '../../../core/services/api_client.dart';
import '../../../shared/models/workspace_models.dart';

class ProjectsService {
  ProjectsService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  Future<List<WorkspaceProject>> listProjects() async {
    // Projects are sorted client-side by recency so the most recently touched
    // workspace appears first in the dashboard.
    final rawProjects = await _apiClient.get('/projects') as List<dynamic>;
    return rawProjects.map(WorkspaceProject.fromJson).toList(growable: false)
      ..sort((a, b) {
        final aDate = a.updatedAt ?? a.createdAt ?? DateTime(2000);
        final bDate = b.updatedAt ?? b.createdAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });
  }

  Future<WorkspaceProject> createProject({
    required String name,
    String description = '',
    String visibility = 'private',
  }) async {
    final rawProject = await _apiClient.post(
      '/projects',
      body: <String, dynamic>{
        'name': name,
        'description': description,
        'visibility': visibility,
      },
    );

    return WorkspaceProject.fromJson(rawProject);
  }

  Future<WorkspaceProject> getProject(String projectId) async {
    final rawProject = await _apiClient.get('/projects/$projectId');
    return WorkspaceProject.fromJson(rawProject);
  }

  Future<ProjectAnalyticsOverview> getAnalyticsOverview(
    String projectId,
  ) async {
    // These analytics endpoints keep the frontend basic: the server already
    // computes counts and rates for the dashboard cards.
    final rawAnalytics =
        await _apiClient.get('/projects/$projectId/analytics/overview');
    return ProjectAnalyticsOverview.fromJson(rawAnalytics);
  }

  Future<ProjectAnalyticsWorkload> getAnalyticsWorkload(
    String projectId,
  ) async {
    final rawAnalytics =
        await _apiClient.get('/projects/$projectId/analytics/workload');
    return ProjectAnalyticsWorkload.fromJson(rawAnalytics);
  }

  Future<WorkspaceProject> updateProject(
    String projectId, {
    String? name,
    String? description,
    String? visibility,
  }) async {
    final rawProject = await _apiClient.patch(
      '/projects/$projectId',
      body: <String, dynamic>{
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (visibility != null) 'visibility': visibility,
      },
    );

    return WorkspaceProject.fromJson(rawProject);
  }

  Future<void> deleteProject(String projectId) async {
    await _apiClient.delete('/projects/$projectId');
  }

  Future<List<ProjectMember>> listMembers(String projectId) async {
    // Member data powers assignment chips, role management, and invite views.
    final rawMembers =
        await _apiClient.get('/projects/$projectId/members') as List<dynamic>;
    return rawMembers.map(ProjectMember.fromJson).toList(growable: false);
  }

  Future<ProjectMember> addMember(
    String projectId, {
    required String userId,
    required String role,
  }) async {
    final rawMember = await _apiClient.post(
      '/projects/$projectId/members',
      body: <String, dynamic>{
        'userId': userId,
        'role': role,
      },
    );

    return ProjectMember.fromJson(rawMember);
  }

  Future<List<ProjectInvite>> listProjectInvites(String projectId) async {
    // Pending invites are a separate endpoint because only owners need them.
    final rawInvites =
        await _apiClient.get('/projects/$projectId/invites') as List<dynamic>;
    return rawInvites.map(ProjectInvite.fromJson).toList(growable: false);
  }

  Future<ProjectInvite> createInvite(
    String projectId, {
    required String username,
    required String role,
  }) async {
    final rawInvite = await _apiClient.post(
      '/projects/$projectId/invites',
      body: <String, dynamic>{
        'username': username,
        'role': role,
      },
    );

    return ProjectInvite.fromJson(rawInvite);
  }

  Future<ProjectMember> updateMember(
    String projectId,
    String memberId, {
    required String role,
  }) async {
    final rawMember = await _apiClient.patch(
      '/projects/$projectId/members/$memberId',
      body: <String, dynamic>{'role': role},
    );

    return ProjectMember.fromJson(rawMember);
  }

  Future<void> deleteMember(String projectId, String memberId) async {
    await _apiClient.delete('/projects/$projectId/members/$memberId');
  }

  Future<List<ProjectTag>> listTags(String projectId) async {
    final rawTags =
        await _apiClient.get('/projects/$projectId/tags') as List<dynamic>;
    return rawTags.map(ProjectTag.fromJson).toList(growable: false);
  }

  Future<ProjectTag> createTag(
    String projectId, {
    required String name,
    required String color,
  }) async {
    final rawTag = await _apiClient.post(
      '/projects/$projectId/tags',
      body: <String, dynamic>{
        'name': name,
        'color': color,
      },
    );

    return ProjectTag.fromJson(rawTag);
  }

  Future<ProjectTag> updateTag(
    String projectId,
    String tagId, {
    String? name,
    String? color,
  }) async {
    final rawTag = await _apiClient.patch(
      '/projects/$projectId/tags/$tagId',
      body: <String, dynamic>{
        if (name != null) 'name': name,
        if (color != null) 'color': color,
      },
    );

    return ProjectTag.fromJson(rawTag);
  }

  Future<void> deleteTag(String projectId, String tagId) async {
    await _apiClient.delete('/projects/$projectId/tags/$tagId');
  }
}
