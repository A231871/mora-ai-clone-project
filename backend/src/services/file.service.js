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

module.exports = {
  buildPublicFileUrl,
  ensureUploadsDir,
  inferFileKind,
  removePhysicalFiles,
  uploadsRoot,
};
