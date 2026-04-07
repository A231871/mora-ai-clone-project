import '../../../core/services/api_client.dart';
import '../../../shared/models/workspace_models.dart';
import '../../auth/services/session_storage.dart';

class UsersService {
  UsersService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  Future<AppUser> getCurrentUser() async {
    // Refreshing the current user keeps local session storage in sync with backend profile changes.
    final rawUser = await _apiClient.get('/users/me');
    final user = AppUser.fromJson(rawUser);
    await SessionStorage.updateUser(user);
    return user;
  }

  Future<AppUser> updateCurrentUser({
    String? displayName,
    String? bio,
  }) async {
    final rawUser = await _apiClient.patch(
      '/users/me',
      body: <String, dynamic>{
        'profile': <String, dynamic>{
          if (displayName != null) 'displayName': displayName,
          if (bio != null) 'bio': bio,
        },
      },
    );

    final user = AppUser.fromJson(rawUser);
    await SessionStorage.updateUser(user);
    return user;
  }

  Future<List<AppUser>> listUsers({String? query}) async {
    final rawUsers = await _apiClient.get(
      '/users',
      queryParameters: <String, String?>{'q': query},
    ) as List<dynamic>;

    return rawUsers.map(AppUser.fromJson).toList(growable: false);
  }

  Future<AppUser> getUser(String userId) async {
    final rawUser = await _apiClient.get('/users/$userId');
    return AppUser.fromJson(rawUser);
  }

  Future<AppUser> updateUserRole(
    String userId, {
    required String systemRole,
  }) async {
    final rawUser = await _apiClient.patch(
      '/users/$userId/role',
      body: <String, dynamic>{'systemRole': systemRole},
    );

    return AppUser.fromJson(rawUser);
  }

  Future<void> deleteUser(String userId) async {
    await _apiClient.delete('/users/$userId');
  }

  Future<List<ProjectInvite>> listMyInvites() async {
    // Invite responses are user-scoped because each invited user controls
    // whether they join or decline a project.
    final rawInvites =
        await _apiClient.get('/users/me/invites') as List<dynamic>;
    return rawInvites.map(ProjectInvite.fromJson).toList(growable: false);
  }

  Future<ProjectInvite> respondToInvite(
    String inviteId, {
    required String action,
  }) async {
    final rawInvite = await _apiClient.patch(
      '/users/me/invites/$inviteId',
      body: <String, dynamic>{'action': action},
    );
    return ProjectInvite.fromJson(rawInvite);
  }
}
