const express = require('express');

const {
  createComment,
  createTask,
  destroyComment,
  destroyTask,
  getTask,
  getTaskComments,
  listTasks,
  patchComment,
  patchTask,
} = require('../controllers/taskController');
const { protect } = require('../middlewares/authMiddleware');

const router = express.Router();

router.use(protect);

router.route('/').get(listTasks).post(createTask);
router.route('/:taskId').get(getTask).patch(patchTask).delete(destroyTask);

router.route('/:taskId/comments').get(getTaskComments).post(createComment);
router.route('/:taskId/comments/:commentId').patch(patchComment).delete(destroyComment);

module.exports = router;
