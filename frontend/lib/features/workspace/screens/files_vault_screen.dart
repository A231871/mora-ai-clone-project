import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/services/api_client.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/workspace_models.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/expandable_filter_panel.dart';
import '../../../shared/widgets/mecha_panel.dart';
import '../../../shared/widgets/workspace_empty_state.dart';
import '../../../shared/widgets/workspace_screen_shell.dart';
import '../../auth/services/session_storage.dart';
import '../services/files_service.dart';

class FilesVaultScreen extends StatefulWidget {
  const FilesVaultScreen({super.key});

  @override
  State<FilesVaultScreen> createState() => _FilesVaultScreenState();
}

class _FilesVaultScreenState extends State<FilesVaultScreen> {
  final FilesService _filesService = FilesService();
  final TextEditingController _searchController = TextEditingController();

  List<FileAsset> _files = const <FileAsset>[];
  AppUser? _currentUser;
  String _selectedKind = 'all';
  bool _loading = true;
  String? _busyFileId;
  bool _filtersExpanded = false;

  bool get _canManageVault => _currentUser != null;

  List<FileAsset> get _visibleFiles {
    final query = _searchController.text.trim().toLowerCase();
    return _files.where((file) {
      if (query.isEmpty) {
        return true;
      }

      final ownerLabel = file.ownerProject?.name ??
          file.ownerTask?.title ??
          file.ownerUser?.resolvedDisplayName ??
          '';

      return file.originalName.toLowerCase().contains(query) ||
          file.kind.toLowerCase().contains(query) ||
          ownerLabel.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFiles() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait<dynamic>([
        _filesService.listFiles(
          kind: _selectedKind == 'all' ? null : _selectedKind,
        ),
        SessionStorage.getCurrentUser(),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _files = results[0] as List<FileAsset>;
        _currentUser = results[1] as AppUser?;
        _loading = false;
        _busyFileId = null;
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
      _showMessage('Failed to load files: $error');
    }
  }

  Future<void> _pickAndUpload() async {
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const <String>[
        'png',
        'jpg',
        'jpeg',
        'pdf',
        'doc',
        'docx'
      ],
    );

    if (picked == null || picked.files.isEmpty) {
      return;
    }

    setState(() => _busyFileId = 'uploading');
    try {
      for (final file in picked.files) {
        final path = file.path;
        if (path == null || path.isEmpty) {
          continue;
        }
        await _filesService.uploadFile(filePath: path);
      }

      if (!mounted) {
        return;
      }
      setState(() => _busyFileId = null);
      _showMessage('Files uploaded successfully.', isError: false);
      await _loadFiles();
    } on ApiException catch (error) {
      _showMessage(error.message);
      if (mounted) {
        setState(() => _busyFileId = null);
      }
    } catch (error) {
      _showMessage('Upload failed: $error');
      if (mounted) {
        setState(() => _busyFileId = null);
      }
    }
  }

  Future<void> _deleteFile(FileAsset file) async {
    setState(() => _busyFileId = file.id);
    try {
      await _filesService.deleteFile(file.id);
      if (!mounted) {
        return;
      }
      _showMessage('File deleted.', isError: false);
      await _loadFiles();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _busyFileId = null);
      _showMessage(error.message);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _busyFileId = null);
      _showMessage('Delete failed: $error');
    }
  }

  void _copyUrl(FileAsset file) {
    Clipboard.setData(ClipboardData(text: file.publicUrl));
    _showMessage('Copied public URL.', isError: false);
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

  String get _fileFiltersSummary {
    final tokens = <String>[];
    final query = _searchController.text.trim();

    if (query.isNotEmpty) {
      tokens.add('Search "$query"');
    }
    if (_selectedKind != 'all') {
      tokens.add('Kind ${_selectedKind.toUpperCase()}');
    }

    return tokens.isEmpty
        ? 'Tap to search and filter your vault.'
        : tokens.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return WorkspaceScreenShell(
      title: 'Files Vault',
      trailing: IconButton(
        onPressed: _loading ? null : _loadFiles,
        icon: const Icon(Icons.refresh, color: AppColors.primary),
      ),
      floatingActionButton: !_canManageVault
          ? null
          : FloatingActionButton(
              onPressed: _busyFileId == 'uploading' ? null : _pickAndUpload,
              child: _busyFileId == 'uploading'
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search uploaded assets, filter by kind, and keep reusable files ready for task attachment.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          ExpandableFilterPanel(
            title: 'Search & Filters',
            summary: _fileFiltersSummary,
            expanded: _filtersExpanded,
            onExpandedChanged: (expanded) =>
                setState(() => _filtersExpanded = expanded),
            collapsedHint: 'Tap to search and filter your vault.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: AppTextStyles.bodyMedium,
                  decoration: const InputDecoration(
                    hintText: 'Search file name, kind, or owner',
                    prefixIcon: Icon(Icons.search, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final kind in const <String>[
                      'all',
                      'image',
                      'pdf',
                      'doc',
                      'docx'
                    ])
                      ChoiceChip(
                        label: Text(kind.toUpperCase()),
                        selected: _selectedKind == kind,
                        onSelected: (_) {
                          setState(() => _selectedKind = kind);
                          _loadFiles();
                        },
                        selectedColor: AppColors.primary.withValues(alpha: 0.3),
                        backgroundColor: AppColors.bgCard,
                        side: BorderSide(
                          color: _selectedKind == kind
                              ? AppColors.primary
                              : AppColors.textSecondary.withValues(alpha: 0.4),
                        ),
                        labelStyle: AppTextStyles.caption.copyWith(
                          color: _selectedKind == kind
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _visibleFiles.isEmpty
                    ? Center(
                        child: WorkspaceEmptyState(
                          icon: Icons.folder_open_outlined,
                          title: 'No Matching Files',
                          message: _files.isEmpty
                              ? 'Upload images or documents here. New task flows can attach from this pool.'
                              : 'Try a different search term or file kind filter.',
                          actionLabel: _canManageVault ? 'Upload File' : null,
                          onAction: _canManageVault ? _pickAndUpload : null,
                        ),
                      )
                    : ListView.separated(
                        itemCount: _visibleFiles.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final file = _visibleFiles[index];
                          final ownerLabel = file.ownerProject?.name ??
                              file.ownerTask?.title ??
                              file.ownerUser?.resolvedDisplayName;

                          return MechaPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _FilePreview(file: file),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            file.originalName,
                                            style: AppTextStyles.titleMedium,
                                          ),
                                          const SizedBox(height: AppSpacing.xs),
                                          Text(
                                            '${file.kind.toUpperCase()} · ${formatBytes(file.size)}',
                                            style: AppTextStyles.caption,
                                          ),
                                          const SizedBox(height: AppSpacing.xs),
                                          Text(
                                            'Added ${formatShortDateTime(file.createdAt)}'
                                            '${file.uploader != null ? ' · uploader ${file.uploader!.resolvedDisplayName}' : ''}',
                                            style: AppTextStyles.bodySmall,
                                          ),
                                          if (file.ownerType != null &&
                                              file.ownerType != 'unassigned')
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: AppSpacing.xs,
                                              ),
                                              child: Text(
                                                ownerLabel == null
                                                    ? 'Attached to ${file.ownerType}'
                                                    : 'Attached to ${file.ownerType}: $ownerLabel',
                                                style: AppTextStyles.caption
                                                    .copyWith(
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Row(
                                  children: [
                                    TextButton.icon(
                                      onPressed: () => _copyUrl(file),
                                      icon: const Icon(
                                        Icons.link,
                                        size: 16,
                                        color: AppColors.primary,
                                      ),
                                      label: Text(
                                        'COPY URL',
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    if (_canManageVault)
                                      TextButton.icon(
                                        onPressed: _busyFileId == file.id
                                            ? null
                                            : () => _deleteFile(file),
                                        icon: _busyFileId == file.id
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : const Icon(
                                                Icons.delete_outline,
                                                size: 16,
                                                color: Colors.redAccent,
                                              ),
                                        label: Text(
                                          'DELETE',
                                          style: AppTextStyles.caption.copyWith(
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                      ),
                                  ],
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

class _FilePreview extends StatelessWidget {
  const _FilePreview({required this.file});

  final FileAsset file;

  @override
  Widget build(BuildContext context) {
    if (file.isImage && file.publicUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: SizedBox(
          width: 84,
          height: 84,
          child: Image.network(
            file.publicUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _placeholder(),
          ),
        ),
      );
    }

    return _placeholder();
  }

  Widget _placeholder() {
    final icon = switch (file.kind) {
      'pdf' => Icons.picture_as_pdf_outlined,
      'doc' => Icons.description_outlined,
      'docx' => Icons.description_outlined,
      _ => Icons.insert_drive_file_outlined,
    };

    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Icon(icon, color: AppColors.primary, size: 30),
    );
  }
}
