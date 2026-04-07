import '../../../core/services/api_client.dart';
import '../../../shared/models/workspace_models.dart';

class FilesService {
  FilesService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  Future<List<FileAsset>> listFiles({
    String? ownerType,
    String? ownerId,
    String? kind,
  }) async {
    final rawFiles = await _apiClient.get(
      '/files',
      queryParameters: <String, String?>{
        'ownerType': ownerType,
        'ownerId': ownerId,
        'kind': kind,
      },
    ) as List<dynamic>;

    return rawFiles.map(FileAsset.fromJson).toList(growable: false);
  }

  Future<FileAsset> uploadFile({
    required String filePath,
    String ownerType = 'unassigned',
    String? ownerId,
    String? kind,
  }) async {
    final rawFile = await _apiClient.postMultipart(
      '/files',
      filePath: filePath,
      fields: <String, String>{
        'ownerType': ownerType,
        if (ownerId != null && ownerId.isNotEmpty) 'ownerId': ownerId,
        if (kind != null && kind.isNotEmpty) 'kind': kind,
      },
    );

    return FileAsset.fromJson(rawFile);
  }

  Future<void> deleteFile(String fileId) async {
    await _apiClient.delete('/files/$fileId');
  }
}
