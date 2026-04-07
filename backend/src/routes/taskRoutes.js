const express = require('express');

const {
  createComment,
  createChecklistItem,
  createTask,
  destroyComment,
  destroyChecklistItem,
  destroyTask,
  getTaskActivity,
  getTaskChecklist,
  getTask,
  getTaskComments,
  listTasks,
  patchChecklistItem,
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
router.route('/:taskId/checklist').get(getTaskChecklist).post(createChecklistItem);
router
  .route('/:taskId/checklist/:itemId')
  .patch(patchChecklistItem)
  .delete(destroyChecklistItem);
router.route('/:taskId/activity').get(getTaskActivity);

module.exports = router;
