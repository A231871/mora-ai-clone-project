const asyncHandler = require('../utils/asyncHandler');
const {
  createAdminFile,
  createAdminProject,
  createAdminProjectInvite,
  createAdminProjectMember,
  createAdminReminder,
  createAdminTag,
  createAdminTask,
  createAdminUser,
  deleteAdminFile,
  deleteAdminProject,
  deleteAdminProjectInvite,
  deleteAdminProjectMember,
  deleteAdminReminder,
  deleteAdminTag,
  deleteAdminTask,
  deleteAdminUser,
  getAdminFileById,
  getAdminProjectById,
  getAdminReminder,
  getAdminTag,
  getAdminTask,
  getAdminUserById,
  listAdminFiles,
  listAdminProjects,
  listAdminReminders,
  listAdminTags,
  listAdminTasks,
  listAdminUsers,
  updateAdminFile,
  updateAdminProject,
  updateAdminProjectMember,
  updateAdminReminder,
  updateAdminTag,
  updateAdminTask,
  updateAdminUser,
} = require('../services/admin.service');

const respond = (res, statusCode, data, message = null) =>
  res.status(statusCode).json({
    success: true,
    ...(message ? { message } : {}),
    data,
  });

const listUsers = asyncHandler(async (req, res) => {
  respond(res, 200, await listAdminUsers(req.query));
});

const createUser = asyncHandler(async (req, res) => {
  respond(res, 201, await createAdminUser(req.body));
});

const getUser = asyncHandler(async (req, res) => {
  respond(res, 200, await getAdminUserById(req.params.userId));
});

const patchUser = asyncHandler(async (req, res) => {
  respond(res, 200, await updateAdminUser(req.params.userId, req.body));
});

const destroyUser = asyncHandler(async (req, res) => {
  await deleteAdminUser(req.params.userId);
  respond(res, 200, null, 'User deleted successfully');
});

const listProjects = asyncHandler(async (req, res) => {
  respond(res, 200, await listAdminProjects(req.query));
});

const createProject = asyncHandler(async (req, res) => {
  respond(res, 201, await createAdminProject(req.user, req.body));
});

const getProject = asyncHandler(async (req, res) => {
  respond(res, 200, await getAdminProjectById(req.params.projectId));
});

const patchProject = asyncHandler(async (req, res) => {
  respond(res, 200, await updateAdminProject(req.params.projectId, req.body));
});

const destroyProject = asyncHandler(async (req, res) => {
  await deleteAdminProject(req.params.projectId);
  respond(res, 200, null, 'Project deleted successfully');
});

const createProjectMember = asyncHandler(async (req, res) => {
  respond(
    res,
    201,
    await createAdminProjectMember(req.user, req.params.projectId, req.body),
  );
});

const createProjectInvite = asyncHandler(async (req, res) => {
  respond(
    res,
    201,
    await createAdminProjectInvite(req.user, req.params.projectId, req.body),
  );
});

const patchProjectMember = asyncHandler(async (req, res) => {
  respond(
    res,
    200,
    await updateAdminProjectMember(
      req.params.projectId,
      req.params.memberId,
      req.body,
    ),
  );
});

const destroyProjectMember = asyncHandler(async (req, res) => {
  await deleteAdminProjectMember(req.params.projectId, req.params.memberId);
  respond(res, 200, null, 'Project member removed successfully');
});

const destroyProjectInvite = asyncHandler(async (req, res) => {
  await deleteAdminProjectInvite(req.params.projectId, req.params.inviteId);
  respond(res, 200, null, 'Project invite removed successfully');
});

const listTasks = asyncHandler(async (req, res) => {
  respond(res, 200, await listAdminTasks(req.query));
});

const createTask = asyncHandler(async (req, res) => {
  respond(res, 201, await createAdminTask(req.user, req.body));
});

const getTask = asyncHandler(async (req, res) => {
  respond(res, 200, await getAdminTask(req.params.taskId));
});

const patchTask = asyncHandler(async (req, res) => {
  respond(res, 200, await updateAdminTask(req.user, req.params.taskId, req.body));
});

const destroyTask = asyncHandler(async (req, res) => {
  await deleteAdminTask(req.params.taskId);
  respond(res, 200, null, 'Task deleted successfully');
});

const listTags = asyncHandler(async (req, res) => {
  respond(res, 200, await listAdminTags(req.query));
});

const createTag = asyncHandler(async (req, res) => {
  respond(res, 201, await createAdminTag(req.user, req.body));
});

const getTag = asyncHandler(async (req, res) => {
  respond(res, 200, await getAdminTag(req.params.tagId));
});

const patchTag = asyncHandler(async (req, res) => {
  respond(res, 200, await updateAdminTag(req.params.tagId, req.body));
});

const destroyTag = asyncHandler(async (req, res) => {
  await deleteAdminTag(req.params.tagId);
  respond(res, 200, null, 'Tag deleted successfully');
});

const listFiles = asyncHandler(async (req, res) => {
  respond(res, 200, await listAdminFiles(req.query));
});

const createFile = asyncHandler(async (req, res) => {
  respond(res, 201, await createAdminFile(req, req.user));
});

const getFile = asyncHandler(async (req, res) => {
  respond(res, 200, await getAdminFileById(req.params.fileId));
});

const patchFile = asyncHandler(async (req, res) => {
  respond(res, 200, await updateAdminFile(req.params.fileId, req.body));
});

const destroyFile = asyncHandler(async (req, res) => {
  await deleteAdminFile(req.params.fileId);
  respond(res, 200, null, 'File deleted successfully');
});

const listReminders = asyncHandler(async (req, res) => {
  const filters = { ...req.query };
  if (filters.isCompleted !== undefined) {
    filters.isCompleted = filters.isCompleted === 'true';
  }

  respond(res, 200, await listAdminReminders(filters));
});

const createReminderEntry = asyncHandler(async (req, res) => {
  respond(res, 201, await createAdminReminder(req.body));
});

const getReminder = asyncHandler(async (req, res) => {
  respond(res, 200, await getAdminReminder(req.params.reminderId));
});

const patchReminder = asyncHandler(async (req, res) => {
  respond(res, 200, await updateAdminReminder(req.params.reminderId, req.body));
});

const destroyReminder = asyncHandler(async (req, res) => {
  await deleteAdminReminder(req.params.reminderId);
  respond(res, 200, null, 'Reminder deleted successfully');
});

module.exports = {
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
};
