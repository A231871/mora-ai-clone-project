const Task = require('../models/Task');
const asyncHandler = require('../utils/asyncHandler');
const {
  createTaskChecklistItem,
  createTaskComment,
  createTaskWithWorkflow,
  deleteTask,
  deleteTaskChecklistItem,
  deleteTaskComment,
  findTaskForUser,
  listTaskActivity,
  listTaskChecklistItems,
  listTaskComments,
  listTasksForUser,
  updateTask,
  updateTaskChecklistItem,
  updateTaskComment,
} = require('../services/task.service');

const listTasks = asyncHandler(async (req, res) => {
  const tasks = await listTasksForUser(req.user, req.query);
  res.status(200).json({
    success: true,
    data: tasks,
  });
});

const createTask = asyncHandler(async (req, res) => {
  const task = await createTaskWithWorkflow(req.user, req.body);
  res.status(201).json({
    success: true,
    data: task,
  });
});

const getTask = asyncHandler(async (req, res) => {
  await findTaskForUser(req.user, req.params.taskId, 'viewer');
  const task = await Task.findById(req.params.taskId)
    .populate('assigneeIds', 'username email profile')
    .populate('tagIds', 'name color')
    .populate('fileIds', 'originalName kind publicUrl taskIds mimeType size');

  res.status(200).json({
    success: true,
    data: task,
  });
});

const patchTask = asyncHandler(async (req, res) => {
  const task = await updateTask(req.user, req.params.taskId, req.body);
  res.status(200).json({
    success: true,
    data: task,
  });
});

const destroyTask = asyncHandler(async (req, res) => {
  await deleteTask(req.user, req.params.taskId);
  res.status(200).json({
    success: true,
    message: 'Task deleted successfully',
  });
});

const getTaskComments = asyncHandler(async (req, res) => {
  const comments = await listTaskComments(req.user, req.params.taskId);
  res.status(200).json({
    success: true,
    data: comments,
  });
});

const getTaskChecklist = asyncHandler(async (req, res) => {
  const items = await listTaskChecklistItems(req.user, req.params.taskId);
  res.status(200).json({
    success: true,
    data: items,
  });
});

const createChecklistItem = asyncHandler(async (req, res) => {
  const item = await createTaskChecklistItem(req.user, req.params.taskId, req.body);
  res.status(201).json({
    success: true,
    data: item,
  });
});

const patchChecklistItem = asyncHandler(async (req, res) => {
  const item = await updateTaskChecklistItem(
    req.user,
    req.params.taskId,
    req.params.itemId,
    req.body,
  );

  res.status(200).json({
    success: true,
    data: item,
  });
});

const destroyChecklistItem = asyncHandler(async (req, res) => {
  await deleteTaskChecklistItem(req.user, req.params.taskId, req.params.itemId);
  res.status(200).json({
    success: true,
    message: 'Checklist item deleted successfully',
  });
});

const getTaskActivity = asyncHandler(async (req, res) => {
  const activity = await listTaskActivity(req.user, req.params.taskId);
  res.status(200).json({
    success: true,
    data: activity,
  });
});

const createComment = asyncHandler(async (req, res) => {
  const comment = await createTaskComment(req.user, req.params.taskId, req.body);
  res.status(201).json({
    success: true,
    data: comment,
  });
});

const patchComment = asyncHandler(async (req, res) => {
  const comment = await updateTaskComment(
    req.user,
    req.params.taskId,
    req.params.commentId,
    req.body,
  );
  res.status(200).json({
    success: true,
    data: comment,
  });
});

const destroyComment = asyncHandler(async (req, res) => {
  await deleteTaskComment(req.user, req.params.taskId, req.params.commentId);
  res.status(200).json({
    success: true,
    message: 'Comment deleted successfully',
  });
});

module.exports = {
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
};
