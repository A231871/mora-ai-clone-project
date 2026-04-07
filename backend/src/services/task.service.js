const mongoose = require('mongoose');

const FileAsset = require('../models/FileAsset');
const ProjectMember = require('../models/ProjectMember');
const Reminder = require('../models/Reminder');
const Tag = require('../models/Tag');
const Task = require('../models/Task');
const TaskActivity = require('../models/TaskActivity');
const TaskChecklistItem = require('../models/TaskChecklistItem');
const TaskComment = require('../models/TaskComment');
const ApiError = require('../utils/apiError');
const {
  attachTaskToFile,
  detachTaskFromFile,
  getFileAttachedTaskIds,
  removePhysicalFiles,
} = require('./file.service');
const { createReminder } = require('./reminder.service');
const {
  getAccessibleProjectIds,
  getProjectAccess,
  requireProjectRole,
} = require('./project.service');

const toObjectIdList = (values = []) => [
  ...new Set((Array.isArray(values) ? values : []).filter(Boolean).map(String)),
];

const toSortedObjectIdList = (values = []) => [...toObjectIdList(values)].sort();

const normalizeOptionalDate = (value, fieldName) => {
  if (value === undefined) {
    return undefined;
  }

  if (value === null || value === '') {
    return null;
  }

  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    throw new ApiError(400, `${fieldName} is invalid`);
  }

  return date;
};

const normalizeEstimatedMinutes = (value) => {
  if (value === undefined) {
    return undefined;
  }

  if (value === null || value === '') {
    return null;
  }

  const parsed = Number(value);
  if (!Number.isInteger(parsed) || parsed < 0) {
    throw new ApiError(
      400,
      'estimatedMinutes must be a non-negative integer',
    );
  }

  return parsed;
};

const applyTaskLifecycleState = (task, previousStatus, nextStatus, now = new Date()) => {
  // Lifecycle timestamps are derived from status transitions so the frontend
  // does not need to manage workflow timing itself.
  if (!nextStatus) {
    return;
  }

  if (nextStatus === 'in_progress' && !task.startedAt) {
    task.startedAt = now;
  }

  if (nextStatus === 'done') {
    if (!task.startedAt) {
      task.startedAt = now;
    }

    task.completedAt = now;
    return;
  }

  if (previousStatus === 'done' && nextStatus !== 'done') {
    task.completedAt = null;
  }
};

const buildInitialTaskLifecycleState = (status, now = new Date()) => {
  const lifecycleState = {
    startedAt: null,
    completedAt: null,
  };

  if (status === 'in_progress') {
    lifecycleState.startedAt = now;
  }

  if (status === 'done') {
    lifecycleState.startedAt = now;
    lifecycleState.completedAt = now;
  }

  return lifecycleState;
};

const datesEqual = (left, right) => {
  const leftTime = left ? new Date(left).getTime() : null;
  const rightTime = right ? new Date(right).getTime() : null;
  return leftTime === rightTime;
};

const recordTaskActivity = async ({
  taskId,
  projectId,
  actorId,
  type,
  message,
  meta = {},
  session = null,
}) => {
  // TaskActivity is append-only audit history. We never "edit history";
  // we create a new activity record for each important action.
  const [activity] = await TaskActivity.create(
    [
      {
        taskId,
        projectId,
        actorId,
        type,
        message,
        meta,
      },
    ],
    session ? { session } : undefined,
  );

  return activity;
};

const validateTaskRelations = async ({
  projectId,
  assigneeIds = [],
  tagIds = [],
  session = null,
}) => {
  // assigneeIds and tagIds are validated against the current project so a task
  // cannot point at users/tags from somewhere else.
  const assigneeList = toObjectIdList(assigneeIds);
  const tagList = toObjectIdList(tagIds);

  if (assigneeList.length > 0) {
    const foundMembers = await ProjectMember.find({
      projectId,
      userId: { $in: assigneeList },
    })
      .select('userId')
      .session(session);

    if (foundMembers.length !== assigneeList.length) {
      throw new ApiError(
        400,
        'One or more assigneeIds are invalid for this project',
      );
    }
  }

  if (tagList.length > 0) {
    const foundTags = await Tag.find({
      _id: { $in: tagList },
      projectId,
    })
      .select('_id')
      .session(session);
    if (foundTags.length !== tagList.length) {
      throw new ApiError(400, 'One or more tagIds are invalid for this project');
    }
  }

  return {
    assigneeIds: assigneeList,
    tagIds: tagList,
  };
};

const findTaskForUser = async (user, taskId, minimumRole = 'viewer') => {
  const task = await Task.findById(taskId);
  if (!task) {
    throw new ApiError(404, 'Task not found');
  }

  const access =
    minimumRole === 'viewer'
      ? await getProjectAccess(user, task.projectId)
      : await requireProjectRole(user, task.projectId, minimumRole);

  return {
    task,
    access,
  };
};

const populateTaskQuery = (query) =>
  query
    .populate('assigneeIds', 'username email profile')
    .populate('tagIds', 'name color')
    .populate('fileIds', 'originalName kind publicUrl taskIds mimeType size');

const populateChecklistItemQuery = (query) =>
  query
    .populate('createdBy', 'username email profile')
    .populate('updatedBy', 'username email profile');

const populateTaskActivityQuery = (query) =>
  query.populate('actorId', 'username email profile');

const getPopulatedTaskById = (taskId) => populateTaskQuery(Task.findById(taskId));

const getPopulatedCommentById = (commentId) =>
  TaskComment.findById(commentId).populate('authorId', 'username email profile');

const getPopulatedChecklistItemById = (itemId) =>
  populateChecklistItemQuery(TaskChecklistItem.findById(itemId));

const syncTaskFileAttachments = async ({
  taskId,
  attachFiles = [],
  detachFiles = [],
  session = null,
  now = new Date(),
}) => {
  // File sharing is handled here so create/update/delete task flows all use the
  // same attach/detach rules.
  for (const file of attachFiles) {
    attachTaskToFile(file, taskId, now);
    await file.save(session ? { session } : undefined);
  }

  for (const file of detachFiles) {
    detachTaskFromFile(file, taskId, now);
    await file.save(session ? { session } : undefined);
  }
};

const listTasksForUser = async (user, filters = {}) => {
  const query = {};

  if (filters.projectId) {
    await getProjectAccess(user, filters.projectId);
    query.projectId = filters.projectId;
  } else {
    const accessibleProjectIds = await getAccessibleProjectIds(user);
    query.projectId = { $in: accessibleProjectIds };
  }

  if (filters.status) {
    query.status = filters.status;
  }

  if (filters.priority) {
    query.priority = filters.priority;
  }

  if (filters.assigneeId) {
    query.assigneeIds = filters.assigneeId;
  }

  if (filters.tagId) {
    query.tagIds = filters.tagId;
  }

  return populateTaskQuery(Task.find(query))
    .sort({ updatedAt: -1 })
    .lean();
};

const createTaskWithWorkflow = async (user, payload) => {
  if (!payload.projectId) {
    throw new ApiError(400, 'projectId is required');
  }

  if (!payload.title) {
    throw new ApiError(400, 'title is required');
  }

  await requireProjectRole(user, payload.projectId, 'editor');

  const session = await mongoose.startSession();
  let createdTaskId = null;

  try {
    await session.withTransaction(async () => {
      // Task creation is transactional because files/reminders/activity logs
      // must stay consistent with the task row.
      const relationData = await validateTaskRelations({
        projectId: payload.projectId,
        assigneeIds: payload.assigneeIds,
        tagIds: payload.tagIds,
        session,
      });

      const fileIds = toObjectIdList(payload.fileIds);
      const status = payload.status || 'todo';
      const dueDate = normalizeOptionalDate(payload.dueDate, 'dueDate');
      const estimatedMinutes = normalizeEstimatedMinutes(payload.estimatedMinutes);
      const lifecycleState = buildInitialTaskLifecycleState(status);
      let filesToAttach = [];

      if (fileIds.length > 0) {
        // Normal users can only attach files they uploaded into their own vault.
        filesToAttach = await FileAsset.find({
          _id: { $in: fileIds },
          uploadedBy: user._id,
        }).session(session);

        if (filesToAttach.length !== fileIds.length) {
          throw new ApiError(400, 'One or more fileIds are invalid');
        }
      }

      const [task] = await Task.create(
        [
          {
            projectId: payload.projectId,
            title: payload.title,
            description: payload.description || '',
            status,
            priority: payload.priority || 'medium',
            dueDate: dueDate ?? null,
            estimatedMinutes: estimatedMinutes ?? null,
            startedAt: lifecycleState.startedAt,
            completedAt: lifecycleState.completedAt,
            assigneeIds: relationData.assigneeIds,
            tagIds: relationData.tagIds,
            fileIds,
            createdBy: user._id,
            updatedBy: user._id,
          },
        ],
        { session },
      );

      createdTaskId = task._id;

      if (payload.reminderAt) {
        // A task reminder is a linked reminder document so it can participate
        // in the same reminder engine as standalone reminders.
        const reminder = await createReminder({
          userId: user._id,
          payload: {
            task: task.title,
            scheduledTime: payload.reminderAt,
            projectId: task.projectId,
            taskId: task._id,
          },
          session,
        });

        task.reminderAt = reminder.scheduledTime;
        task.reminderId = reminder._id;
      }

      if (fileIds.length > 0) {
        await syncTaskFileAttachments({
          taskId: task._id,
          attachFiles: filesToAttach,
          session,
        });
      }

      await task.save({ session });

      await recordTaskActivity({
        taskId: task._id,
        projectId: task.projectId,
        actorId: user._id,
        type: 'task.created',
        message: 'Created the task',
        meta: {
          status: task.status,
          priority: task.priority,
          dueDate: task.dueDate,
          estimatedMinutes: task.estimatedMinutes,
        },
        session,
      });
    });
  } finally {
    await session.endSession();
  }

  return getPopulatedTaskById(createdTaskId);
};

const updateTask = async (user, taskId, payload) => {
  const { task } = await findTaskForUser(user, taskId, 'editor');
  const session = await mongoose.startSession();

  try {
    await session.withTransaction(async () => {
      const previousStatus = task.status;
      const previousAssigneeIds = toSortedObjectIdList(task.assigneeIds);
      const previousTagIds = toSortedObjectIdList(task.tagIds);
      const previousDueDate = task.dueDate;
      const previousEstimatedMinutes = task.estimatedMinutes;

      const relationData = await validateTaskRelations({
        projectId: task.projectId,
        assigneeIds:
          payload.assigneeIds !== undefined ? payload.assigneeIds : task.assigneeIds,
        tagIds: payload.tagIds !== undefined ? payload.tagIds : task.tagIds,
        session,
      });

      if (payload.title !== undefined) {
        task.title = payload.title;
      }

      if (payload.description !== undefined) {
        task.description = payload.description;
      }

      if (payload.status !== undefined) {
        applyTaskLifecycleState(task, previousStatus, payload.status);
        task.status = payload.status;
      }

      if (payload.priority !== undefined) {
        task.priority = payload.priority;
      }

      if (payload.dueDate !== undefined) {
        task.dueDate = normalizeOptionalDate(payload.dueDate, 'dueDate');
      }

      if (payload.estimatedMinutes !== undefined) {
        task.estimatedMinutes = normalizeEstimatedMinutes(payload.estimatedMinutes);
      }

      task.assigneeIds = relationData.assigneeIds;
      task.tagIds = relationData.tagIds;
      task.updatedBy = user._id;

      if (payload.fileIds !== undefined) {
        // The client sends the full desired file list. We diff current vs next
        // to determine which attachments to add and which to remove.
        const nextFileIds = toObjectIdList(payload.fileIds);
        const currentFileIds = toObjectIdList(task.fileIds);
        const toAttach = nextFileIds.filter((id) => !currentFileIds.includes(id));
        const toDetach = currentFileIds.filter((id) => !nextFileIds.includes(id));
        const touchedFileIds = [...new Set([...toAttach, ...toDetach])];
        let touchedFiles = [];

        if (touchedFileIds.length > 0) {
          touchedFiles = await FileAsset.find({
            _id: { $in: touchedFileIds },
          }).session(session);
        }

        if (toAttach.length > 0) {
          const attachFiles = touchedFiles.filter(
            (file) =>
              toAttach.includes(file._id.toString()) &&
              file.uploadedBy.toString() === user._id.toString(),
          );

          if (attachFiles.length !== toAttach.length) {
            throw new ApiError(400, 'One or more fileIds are invalid');
          }
        }

        if (touchedFiles.length > 0) {
          await syncTaskFileAttachments({
            taskId: task._id,
            attachFiles: touchedFiles.filter((file) =>
              toAttach.includes(file._id.toString()),
            ),
            detachFiles: touchedFiles.filter((file) =>
              toDetach.includes(file._id.toString()),
            ),
            session,
          });
        }

        task.fileIds = nextFileIds;
      }

      if (payload.reminderAt !== undefined) {
        if (!payload.reminderAt) {
          if (task.reminderId) {
            await Reminder.deleteOne({ _id: task.reminderId }).session(session);
            task.reminderId = null;
          }
          task.reminderAt = null;
        } else if (task.reminderId) {
          const reminder = await Reminder.findById(task.reminderId).session(session);
          if (reminder) {
            reminder.message = task.title;
            reminder.scheduledTime = new Date(payload.reminderAt);
            reminder.projectId = task.projectId;
            reminder.taskId = task._id;
            reminder.isCompleted = false;
            await reminder.save({ session });
            task.reminderAt = reminder.scheduledTime;
          }
        } else {
          const reminder = await createReminder({
            userId: user._id,
            payload: {
              task: task.title,
              scheduledTime: payload.reminderAt,
              projectId: task.projectId,
              taskId: task._id,
            },
            session,
          });

          task.reminderId = reminder._id;
          task.reminderAt = reminder.scheduledTime;
        }
      } else if (task.reminderId && payload.title !== undefined) {
        const reminder = await Reminder.findById(task.reminderId).session(session);
        if (reminder) {
          reminder.message = task.title;
          await reminder.save({ session });
        }
      }

      await task.save({ session });

      const nextAssigneeIds = toSortedObjectIdList(task.assigneeIds);
      const nextTagIds = toSortedObjectIdList(task.tagIds);

      // Each major change emits its own activity record so the UI can present
      // a readable audit trail on the task detail screen.
      if (payload.status !== undefined && previousStatus !== task.status) {
        await recordTaskActivity({
          taskId: task._id,
          projectId: task.projectId,
          actorId: user._id,
          type: 'task.status_changed',
          message: `Changed task status from ${previousStatus} to ${task.status}`,
          meta: {
            previousStatus,
            nextStatus: task.status,
          },
          session,
        });
      }

      if (
        payload.assigneeIds !== undefined &&
        JSON.stringify(previousAssigneeIds) !== JSON.stringify(nextAssigneeIds)
      ) {
        await recordTaskActivity({
          taskId: task._id,
          projectId: task.projectId,
          actorId: user._id,
          type: 'task.assignees_changed',
          message: 'Updated task assignees',
          meta: {
            previousAssigneeIds,
            nextAssigneeIds,
          },
          session,
        });
      }

      if (
        payload.tagIds !== undefined &&
        JSON.stringify(previousTagIds) !== JSON.stringify(nextTagIds)
      ) {
        await recordTaskActivity({
          taskId: task._id,
          projectId: task.projectId,
          actorId: user._id,
          type: 'task.tags_changed',
          message: 'Updated task tags',
          meta: {
            previousTagIds,
            nextTagIds,
          },
          session,
        });
      }

      if (
        payload.dueDate !== undefined &&
        !datesEqual(previousDueDate, task.dueDate)
      ) {
        await recordTaskActivity({
          taskId: task._id,
          projectId: task.projectId,
          actorId: user._id,
          type: 'task.due_date_changed',
          message: 'Updated task due date',
          meta: {
            previousDueDate,
            nextDueDate: task.dueDate,
          },
          session,
        });
      }

      if (
        payload.estimatedMinutes !== undefined &&
        previousEstimatedMinutes !== task.estimatedMinutes
      ) {
        await recordTaskActivity({
          taskId: task._id,
          projectId: task.projectId,
          actorId: user._id,
          type: 'task.estimate_changed',
          message: 'Updated task estimate',
          meta: {
            previousEstimatedMinutes,
            nextEstimatedMinutes: task.estimatedMinutes,
          },
          session,
        });
      }
    });
  } finally {
    await session.endSession();
  }

  return getPopulatedTaskById(task._id);
};

const deleteTaskTree = async (task) => {
  const storagePaths = [];
  const session = await mongoose.startSession();

  try {
    await session.withTransaction(async () => {
      // Shared files are detached from this task only.
      // Files exclusively owned by this task are physically deleted.
      if (task.fileIds.length > 0) {
        const files = await FileAsset.find({ _id: { $in: task.fileIds } }).session(
          session,
        );

        for (const file of files) {
          const nextTaskIds = getFileAttachedTaskIds(file).filter(
            (attachedTaskId) => attachedTaskId !== task._id.toString(),
          );
          const isLegacySingleTaskOwner =
            file.ownerType === 'task' &&
            file.ownerId?.toString() === task._id.toString() &&
            nextTaskIds.length === 0;

          if (isLegacySingleTaskOwner) {
            storagePaths.push(file.storagePath);
            await file.deleteOne({ session });
            continue;
          }

          detachTaskFromFile(file, task._id);
          await file.save({ session });
        }
      }

      if (task.reminderId) {
        await Reminder.deleteOne({ _id: task.reminderId }).session(session);
      }

      await Reminder.deleteMany({ taskId: task._id }).session(session);
      // Checklist items, activity, and comments are task-scoped subdocuments in practice,
      // so they are removed together with the parent task.
      await TaskChecklistItem.deleteMany({ taskId: task._id }).session(session);
      await TaskActivity.deleteMany({ taskId: task._id }).session(session);
      await TaskComment.deleteMany({ taskId: task._id }).session(session);
      await task.deleteOne({ session });
    });
  } finally {
    await session.endSession();
  }

  removePhysicalFiles(storagePaths);
};

const deleteTask = async (user, taskId) => {
  const { task } = await findTaskForUser(user, taskId, 'editor');
  await deleteTaskTree(task);
};

const listTaskComments = async (user, taskId) => {
  const { task } = await findTaskForUser(user, taskId, 'viewer');
  return TaskComment.find({ taskId: task._id })
    .populate('authorId', 'username email profile')
    .sort({ createdAt: 1 })
    .lean();
};

const createTaskComment = async (user, taskId, payload) => {
  const { task } = await findTaskForUser(user, taskId, 'viewer');

  if (!payload.content) {
    throw new ApiError(400, 'content is required');
  }

  const comment = await TaskComment.create({
    projectId: task.projectId,
    taskId: task._id,
    authorId: user._id,
    content: payload.content,
  });

  await recordTaskActivity({
    taskId: task._id,
    projectId: task.projectId,
    actorId: user._id,
    type: 'comment.created',
    message: 'Added a task comment',
    meta: {
      commentId: comment._id,
    },
  });

  return getPopulatedCommentById(comment._id);
};

const updateTaskComment = async (user, taskId, commentId, payload) => {
  const { task, access } = await findTaskForUser(user, taskId, 'viewer');
  const comment = await TaskComment.findOne({ _id: commentId, taskId: task._id });

  if (!comment) {
    throw new ApiError(404, 'Comment not found');
  }

  const canEdit =
    comment.authorId.toString() === user._id.toString() ||
    ['owner', 'editor'].includes(access.projectRole);

  if (!canEdit) {
    throw new ApiError(403, 'You cannot edit this comment');
  }

  comment.content = payload.content || comment.content;
  comment.editedAt = new Date();
  await comment.save();

  await recordTaskActivity({
    taskId: task._id,
    projectId: task.projectId,
    actorId: user._id,
    type: 'comment.updated',
    message: 'Edited a task comment',
    meta: {
      commentId: comment._id,
    },
  });

  return getPopulatedCommentById(comment._id);
};

const deleteTaskComment = async (user, taskId, commentId) => {
  const { task, access } = await findTaskForUser(user, taskId, 'viewer');
  const comment = await TaskComment.findOne({ _id: commentId, taskId: task._id });

  if (!comment) {
    throw new ApiError(404, 'Comment not found');
  }

  const canDelete =
    comment.authorId.toString() === user._id.toString() ||
    ['owner', 'editor'].includes(access.projectRole);

  if (!canDelete) {
    throw new ApiError(403, 'You cannot delete this comment');
  }

  await comment.deleteOne();

  await recordTaskActivity({
    taskId: task._id,
    projectId: task.projectId,
    actorId: user._id,
    type: 'comment.deleted',
    message: 'Deleted a task comment',
    meta: {
      commentId,
    },
  });
};

const listTaskChecklistItems = async (user, taskId) => {
  const { task } = await findTaskForUser(user, taskId, 'viewer');

  return populateChecklistItemQuery(
    TaskChecklistItem.find({ taskId: task._id }).sort({ createdAt: 1 }),
  ).lean();
};

const createTaskChecklistItem = async (user, taskId, payload) => {
  const { task } = await findTaskForUser(user, taskId, 'editor');

  if (!payload.content || !payload.content.trim()) {
    throw new ApiError(400, 'content is required');
  }

  const [item] = await TaskChecklistItem.create([
    {
      taskId: task._id,
      projectId: task.projectId,
      content: payload.content.trim(),
      isCompleted: false,
      createdBy: user._id,
      updatedBy: user._id,
    },
  ]);

  await recordTaskActivity({
    taskId: task._id,
    projectId: task.projectId,
    actorId: user._id,
    type: 'checklist.created',
    message: `Added checklist item "${item.content}"`,
    meta: {
      checklistItemId: item._id,
    },
  });

  return getPopulatedChecklistItemById(item._id);
};

const updateTaskChecklistItem = async (user, taskId, itemId, payload) => {
  const { task } = await findTaskForUser(user, taskId, 'editor');
  const item = await TaskChecklistItem.findOne({ _id: itemId, taskId: task._id });

  if (!item) {
    throw new ApiError(404, 'Checklist item not found');
  }

  const previousContent = item.content;
  const previousCompletion = item.isCompleted;

  if (payload.content !== undefined) {
    if (!payload.content || !payload.content.trim()) {
      throw new ApiError(400, 'content is required');
    }
    item.content = payload.content.trim();
  }

  if (payload.isCompleted !== undefined) {
    item.isCompleted = Boolean(payload.isCompleted);
    item.completedAt = item.isCompleted ? new Date() : null;
  }

  item.updatedBy = user._id;
  await item.save();

  let activityType = 'checklist.updated';
  let activityMessage = `Updated checklist item "${item.content}"`;

  if (payload.isCompleted !== undefined && previousCompletion !== item.isCompleted) {
    activityType = item.isCompleted ? 'checklist.completed' : 'checklist.reopened';
    activityMessage = item.isCompleted
      ? `Completed checklist item "${item.content}"`
      : `Reopened checklist item "${item.content}"`;
  } else if (
    payload.content !== undefined &&
    previousContent !== item.content
  ) {
    activityMessage = `Renamed checklist item to "${item.content}"`;
  }

  await recordTaskActivity({
    taskId: task._id,
    projectId: task.projectId,
    actorId: user._id,
    type: activityType,
    message: activityMessage,
    meta: {
      checklistItemId: item._id,
      previousContent,
      previousCompletion,
      nextContent: item.content,
      nextCompletion: item.isCompleted,
    },
  });

  return getPopulatedChecklistItemById(item._id);
};

const deleteTaskChecklistItem = async (user, taskId, itemId) => {
  const { task } = await findTaskForUser(user, taskId, 'editor');
  const item = await TaskChecklistItem.findOne({ _id: itemId, taskId: task._id });

  if (!item) {
    throw new ApiError(404, 'Checklist item not found');
  }

  const { content } = item;
  await item.deleteOne();

  await recordTaskActivity({
    taskId: task._id,
    projectId: task.projectId,
    actorId: user._id,
    type: 'checklist.deleted',
    message: `Deleted checklist item "${content}"`,
    meta: {
      checklistItemId: itemId,
    },
  });
};

const listTaskActivity = async (user, taskId) => {
  const { task } = await findTaskForUser(user, taskId, 'viewer');

  return populateTaskActivityQuery(
    TaskActivity.find({ taskId: task._id }).sort({ createdAt: -1 }),
  ).lean();
};

module.exports = {
  applyTaskLifecycleState,
  buildInitialTaskLifecycleState,
  createTaskChecklistItem,
  createTaskComment,
  createTaskWithWorkflow,
  deleteTask,
  deleteTaskChecklistItem,
  deleteTaskTree,
  deleteTaskComment,
  findTaskForUser,
  getPopulatedChecklistItemById,
  getPopulatedCommentById,
  getPopulatedTaskById,
  listTaskActivity,
  listTaskChecklistItems,
  listTaskComments,
  listTasksForUser,
  normalizeEstimatedMinutes,
  normalizeOptionalDate,
  populateChecklistItemQuery,
  populateTaskActivityQuery,
  populateTaskQuery,
  recordTaskActivity,
  updateTask,
  updateTaskChecklistItem,
  updateTaskComment,
  validateTaskRelations,
};
