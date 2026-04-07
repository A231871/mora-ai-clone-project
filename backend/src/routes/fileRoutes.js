const express = require('express');

const {
  deleteFile,
  listFiles,
  uploadFile,
} = require('../controllers/fileController');
const { protect } = require('../middlewares/authMiddleware');
const { uploadSingleFile } = require('../middlewares/uploadMiddleware');

const router = express.Router();

router.use(protect);

router.get('/', listFiles);
router.post('/', uploadSingleFile, uploadFile);
router.delete('/:fileId', deleteFile);

module.exports = router;
