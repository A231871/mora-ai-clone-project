const crypto = require('crypto');
const path = require('path');

const multer = require('multer');

const { ensureUploadsDir, inferFileKind, uploadsRoot } = require('../services/file.service');

ensureUploadsDir();

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, uploadsRoot),
  filename: (_req, file, cb) => {
    const extension = path.extname(file.originalname || '').toLowerCase();
    cb(null, `${Date.now()}-${crypto.randomUUID()}${extension}`);
  },
});

const fileFilter = (_req, file, cb) => {
  const kind = inferFileKind(file);
  if (!kind) {
    return cb(new Error('Only image, pdf, doc, and docx files are allowed'));
  }

  return cb(null, true);
};

const uploadSingleFile = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024,
  },
}).single('file');

module.exports = {
  uploadSingleFile,
};
