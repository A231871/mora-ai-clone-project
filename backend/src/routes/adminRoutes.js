const express = require('express');

const {
  createFile,
  createProject,
  createProjectInvite,
  createProjectMember,
  createReminderEntry,
  createTag,
  createTask,
  createUser,
  destroyFile,
  destroyProject,
  destroyProjectInvite,
  destroyProjectMember,
  destroyReminder,
  destroyTag,
  destroyTask,
  destroyUser,
  getFile,
  getProject,
  getReminder,
  getTag,
  getTask,
  getUser,
  listFiles,
  listProjects,
  listReminders,
  listTags,
  listTasks,
  listUsers,
  patchFile,
  patchProject,
  patchProjectMember,
  patchReminder,
  patchTag,
  patchTask,
  patchUser,
} = require('../controllers/adminController');
const {
  authorizeSystemRoles,
  protect,
} = require('../middlewares/authMiddleware');
const { uploadSingleFile } = require('../middlewares/uploadMiddleware');

const router = express.Router();

router.use(protect, authorizeSystemRoles('admin'));

router.route('/users').get(listUsers).post(createUser);
router.route('/users/:userId').get(getUser).patch(patchUser).delete(destroyUser);

router.route('/projects').get(listProjects).post(createProject);
router.route('/projects/:projectId').get(getProject).patch(patchProject).delete(destroyProject);
router.route('/projects/:projectId/members').post(createProjectMember);
router.route('/projects/:projectId/invites').post(createProjectInvite);
router
  .route('/projects/:projectId/members/:memberId')
  .patch(patchProjectMember)
  .delete(destroyProjectMember);
router.delete('/projects/:projectId/invites/:inviteId', destroyProjectInvite);

router.route('/tasks').get(listTasks).post(createTask);
router.route('/tasks/:taskId').get(getTask).patch(patchTask).delete(destroyTask);

router.route('/tags').get(listTags).post(createTag);
router.route('/tags/:tagId').get(getTag).patch(patchTag).delete(destroyTag);

router.route('/files').get(listFiles).post(uploadSingleFile, createFile);
router.route('/files/:fileId').get(getFile).patch(patchFile).delete(destroyFile);

router.route('/reminders').get(listReminders).post(createReminderEntry);
router
  .route('/reminders/:reminderId')
  .get(getReminder)
  .patch(patchReminder)
  .delete(destroyReminder);

module.exports = router;
