const FileAsset = require('../models/FileAsset');
const Task = require('../models/Task');
const asyncHandler = require('../utils/asyncHandler');
const ApiError = require('../utils/apiError');
const {
  buildPublicFileUrl,
  getFileAttachedTaskIds,
  inferFileKind,
  removePhysicalFiles,
} = require('../services/file.service');
const {
  getProjectAccess,
  requireProjectRole,
} = require('../services/project.service');
const { findTaskForUser } = require('../services/task.service');

const ensureFileActionAccess = async (user, ownerType, ownerId, minimumRole = 'viewer') => {
  // File permissions depend on the resource the file is attached to.
  // Project/task-linked files inherit access from that project/task.
  if (!ownerType || ownerType === 'unassigned') {
    throw new ApiError(403, 'You do not have permission for this file action');
  }

  if (ownerType === 'user') {
    if (!ownerId || ownerId.toString() !== user._id.toString()) {
      throw new ApiError(403, 'You cannot manage files for another user');
    }
    return;
  }

  if (ownerType === 'project') {
    if (minimumRole === 'viewer') {
      await getProjectAccess(user, ownerId);
    } else {
      await requireProjectRole(user, ownerId, minimumRole);
    }
    return;
  }

  if (ownerType === 'task') {
    await findTaskForUser(user, ownerId, minimumRole);
    return;
  }

  throw new ApiError(403, 'You do not have permission for this file action');
};

const listFiles = asyncHandler(async (req, res) => {
  const query = {};
  const { ownerType, ownerId, kind } = req.query;

  if (kind) {
    query.kind = kind;
  }

  if (ownerType) {
    if (ownerType !== 'task') {
      query.ownerType = ownerType;
    }
  }

  if (ownerId) {
    if (ownerType === 'task') {
      // Task filtering must support both the old single-task ownership model
      // and the new reusable file model with taskIds.
      query.$or = [
        { ownerType: 'task', ownerId },
        { taskIds: ownerId },
      ];
    } else {
      query.ownerId = ownerId;
    }
  }

  if (ownerType && ownerId) {
    await ensureFileActionAccess(req.user, ownerType, ownerId, 'viewer');
  } else {
    query.uploadedBy = req.user._id;
  }

  const files = await FileAsset.find(query).sort({ createdAt: -1 }).lean();

  res.status(200).json({
    success: true,
    data: files,
  });
});

const uploadFile = asyncHandler(async (req, res) => {
  if (!req.file) {
    throw new ApiError(400, 'file is required');
  }

  const ownerType = req.body.ownerType || 'unassigned';
  const ownerId = req.body.ownerId || null;
  const inferredKind = inferFileKind(req.file);
  const kind = req.body.kind || inferredKind;

  if (!kind || !inferredKind || kind !== inferredKind) {
    removePhysicalFiles([req.file.path]);
    throw new ApiError(400, 'Unsupported file kind');
  }

  if (ownerType !== 'unassigned' && !ownerId) {
    removePhysicalFiles([req.file.path]);
    throw new ApiError(400, 'ownerId is required unless ownerType is unassigned');
  }

  if (ownerType !== 'unassigned') {
    await ensureFileActionAccess(req.user, ownerType, ownerId, 'editor');
  }

  const fileAsset = await FileAsset.create({
    uploadedBy: req.user._id,
    ownerType,
    ownerId,
    // Direct task uploads are initialized with a single task link, but the same file
    // can later be attached to other tasks as well.
    taskIds: ownerType === 'task' && ownerId ? [ownerId] : [],
    kind,
    originalName: req.file.originalname,
    storedName: req.file.filename,
    mimeType: req.file.mimetype,
    size: req.file.size,
    storagePath: req.file.path,
    publicUrl: buildPublicFileUrl(req, req.file.filename),
    attachedAt: ownerType === 'unassigned' ? null : new Date(),
  });

  if (ownerType === 'task' && ownerId) {
    await Task.updateOne({ _id: ownerId }, { $addToSet: { fileIds: fileAsset._id } });
  }

  res.status(201).json({
    success: true,
    data: fileAsset,
  });
});

const deleteFile = asyncHandler(async (req, res) => {
  const fileAsset = await FileAsset.findById(req.params.fileId);
  if (!fileAsset) {
    throw new ApiError(404, 'File not found');
  }

  const isOwner = fileAsset.uploadedBy.toString() === req.user._id.toString();
  if (!isOwner) {
    if (fileAsset.ownerType === 'unassigned') {
      throw new ApiError(403, 'You do not have permission to delete this file');
    }

    await ensureFileActionAccess(
      req.user,
      fileAsset.ownerType,
      fileAsset.ownerId,
      'editor',
    );
  }

  // Deleting a file is stronger than detaching it: every task reference is cleaned up
  // before the metadata row and physical file are removed.
  const linkedTaskIds = getFileAttachedTaskIds(fileAsset);
  if (linkedTaskIds.length > 0) {
    await Task.updateMany(
      { _id: { $in: linkedTaskIds } },
      { $pull: { fileIds: fileAsset._id } },
    );
  }

  const storagePath = fileAsset.storagePath;
  await fileAsset.deleteOne();
  removePhysicalFiles([storagePath]);

  res.status(200).json({
    success: true,
    message: 'File deleted successfully',
  });
});

module.exports = {
  deleteFile,
  listFiles,
  uploadFile,
};
