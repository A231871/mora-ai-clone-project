const fs = require('fs');
const path = require('path');

const uploadsRoot = path.resolve(__dirname, '../../uploads');

const ensureUploadsDir = () => {
  if (!fs.existsSync(uploadsRoot)) {
    fs.mkdirSync(uploadsRoot, { recursive: true });
  }
};

const inferFileKind = (file) => {
  const mimeType = (file?.mimetype || '').toLowerCase();
  const extension = path.extname(file?.originalname || '').toLowerCase();

  if (
    mimeType.startsWith('image/') ||
    ['.png', '.jpg', '.jpeg'].includes(extension)
  ) {
    return 'image';
  }

  if (mimeType === 'application/pdf' || extension === '.pdf') {
    return 'pdf';
  }

  if (mimeType === 'application/msword' || extension === '.doc') {
    return 'doc';
  }

  if (
    mimeType ===
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document' ||
    extension === '.docx'
  ) {
    return 'docx';
  }

  return null;
};

const buildPublicFileUrl = (req, storedName) =>
  `${req.protocol}://${req.get('host')}/uploads/${storedName}`;

const removePhysicalFiles = (storagePaths = []) => {
  for (const storagePath of storagePaths) {
    if (!storagePath) {
      continue;
    }

    try {
      if (fs.existsSync(storagePath)) {
        fs.unlinkSync(storagePath);
      }
    } catch (error) {
      console.error('[File Cleanup] Failed to delete file:', storagePath, error);
    }
  }
};

const toUniqueIdStrings = (values = []) => [
  ...new Set((Array.isArray(values) ? values : []).filter(Boolean).map(String)),
];

const getFileAttachedTaskIds = (file) => {
  const taskIds = toUniqueIdStrings(file?.taskIds);

  if (file?.ownerType === 'task' && file?.ownerId) {
    const ownerTaskId = file.ownerId.toString();
    if (!taskIds.includes(ownerTaskId)) {
      taskIds.push(ownerTaskId);
    }
  }

  return taskIds;
};

const setFileAttachedTaskIds = (file, taskIds, now = new Date()) => {
  const normalizedTaskIds = toUniqueIdStrings(taskIds);
  const ownerTaskId =
    file?.ownerType === 'task' && file?.ownerId
      ? file.ownerId.toString()
      : null;
  const keepLegacyTaskOwner =
    ownerTaskId &&
    normalizedTaskIds.length === 1 &&
    normalizedTaskIds[0] === ownerTaskId;

  if (file?.ownerType === 'task' && !keepLegacyTaskOwner) {
    file.ownerType = 'unassigned';
    file.ownerId = null;
  }

  file.taskIds = normalizedTaskIds;
  file.attachedAt =
    normalizedTaskIds.length > 0 || file.ownerType !== 'unassigned'
      ? file.attachedAt || now
      : null;

  return normalizedTaskIds;
};

const attachTaskToFile = (file, taskId, now = new Date()) => {
  const nextTaskIds = getFileAttachedTaskIds(file);
  const normalizedTaskId = taskId?.toString();

  if (normalizedTaskId && !nextTaskIds.includes(normalizedTaskId)) {
    nextTaskIds.push(normalizedTaskId);
  }

  return setFileAttachedTaskIds(file, nextTaskIds, now);
};

const detachTaskFromFile = (file, taskId, now = new Date()) => {
  const normalizedTaskId = taskId?.toString();
  const nextTaskIds = getFileAttachedTaskIds(file).filter(
    (candidateId) => candidateId !== normalizedTaskId,
  );

  return setFileAttachedTaskIds(file, nextTaskIds, now);
};

module.exports = {
  attachTaskToFile,
  buildPublicFileUrl,
  detachTaskFromFile,
  ensureUploadsDir,
  getFileAttachedTaskIds,
  inferFileKind,
  removePhysicalFiles,
  setFileAttachedTaskIds,
  uploadsRoot,
};
