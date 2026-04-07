const mongoose = require('mongoose');

const FileAsset = require('../models/FileAsset');
const ProjectMember = require('../models/ProjectMember');
const Reminder = require('../models/Reminder');
const Tag = require('../models/Tag');
const Task = require('../models/Task');
const TaskComment = require('../models/TaskComment');
const ApiError = require('../utils/apiError');
const { removePhysicalFiles } = require('./file.service');
const { createReminder } = require('./reminder.service');
const {
  getAccessibleProjectIds,
  getProjectAccess,
  requireProjectRole,
} = require('./project.service');

const toObjectIdList = (values = []) => [
  ...new Set((Array.isArray(values) ? values : []).filter(Boolean).map(String)),
];

const validateTaskRelations = async ({
  projectId,
  assigneeIds = [],
  tagIds = [],
  session = null,
}) => {
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
    .populate('fileIds', 'originalName kind publicUrl');

const getPopulatedTaskById = (taskId) =>
  populateTaskQuery(Task.findById(taskId));

const getPopulatedCommentById = (commentId) =>
  TaskComment.findById(commentId).populate('authorId', 'username email profile');

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

  return Task.find(query)
    .populate('assigneeIds', 'username email profile')
    .populate('tagIds', 'name color')
    .populate('fileIds', 'originalName kind publicUrl')
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

  await session.withTransaction(async () => {
    const relationData = await validateTaskRelations({
      projectId: payload.projectId,
      assigneeIds: payload.assigneeIds,
      tagIds: payload.tagIds,
      session,
    });

    const fileIds = toObjectIdList(payload.fileIds);

    if (fileIds.length > 0) {
      const files = await FileAsset.find({
        _id: { $in: fileIds },
        uploadedBy: user._id,
      }).session(session);

      if (files.length !== fileIds.length) {
        throw new ApiError(400, 'One or more fileIds are invalid');
      }
    }

    const [task] = await Task.create(
      [
        {
          projectId: payload.projectId,
          title: payload.title,
          description: payload.description || '',
          status: payload.status || 'todo',
          priority: payload.priority || 'medium',
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
      await FileAsset.updateMany(
        { _id: { $in: fileIds } },
        {
          $set: {
            ownerType: 'task',
            ownerId: task._id,
            attachedAt: new Date(),
          },
        },
        { session },
      );
    }

    await task.save({ session });
  });

  await session.endSession();

  return await getPopulatedTaskById(createdTaskId);
};

const updateTask = async (user, taskId, payload) => {
  const { task } = await findTaskForUser(user, taskId, 'editor');
  const session = await mongoose.startSession();

  await session.withTransaction(async () => {
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
      task.status = payload.status;
    }

    if (payload.priority !== undefined) {
      task.priority = payload.priority;
    }

    task.assigneeIds = relationData.assigneeIds;
    task.tagIds = relationData.tagIds;
    task.updatedBy = user._id;

    if (payload.fileIds !== undefined) {
      const nextFileIds = toObjectIdList(payload.fileIds);
      const currentFileIds = toObjectIdList(task.fileIds);
      const toAttach = nextFileIds.filter((id) => !currentFileIds.includes(id));
      const toDetach = currentFileIds.filter((id) => !nextFileIds.includes(id));

      if (toAttach.length > 0) {
        const files = await FileAsset.find({
          _id: { $in: toAttach },
          uploadedBy: user._id,
        }).session(session);

        if (files.length !== toAttach.length) {
          throw new ApiError(400, 'One or more fileIds are invalid');
        }

        await FileAsset.updateMany(
          { _id: { $in: toAttach } },
          {
            $set: {
              ownerType: 'task',
              ownerId: task._id,
              attachedAt: new Date(),
            },
          },
          { session },
        );
      }

      if (toDetach.length > 0) {
        await FileAsset.updateMany(
          { _id: { $in: toDetach } },
          {
            $set: {
              ownerType: 'unassigned',
              attachedAt: null,
            },
            $unset: {
              ownerId: 1,
            },
          },
          { session },
        );
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
  });

  await session.endSession();

  return await getPopulatedTaskById(task._id);
};

const deleteTaskTree = async (task) => {
  const storagePaths = [];
  const session = await mongoose.startSession();

  await session.withTransaction(async () => {
    if (task.fileIds.length > 0) {
      const files = await FileAsset.find({ _id: { $in: task.fileIds } }).session(session);
      storagePaths.push(...files.map((file) => file.storagePath));
      await FileAsset.deleteMany({ _id: { $in: task.fileIds } }).session(session);
    }

    if (task.reminderId) {
      await Reminder.deleteOne({ _id: task.reminderId }).session(session);
    }

    await Reminder.deleteMany({ taskId: task._id }).session(session);
    await TaskComment.deleteMany({ taskId: task._id }).session(session);
    await task.deleteOne({ session });
  });

  await session.endSession();
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

  return await getPopulatedCommentById(comment._id);
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
  return await getPopulatedCommentById(comment._id);
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
};

module.exports = {
  createTaskComment,
  createTaskWithWorkflow,
  deleteTask,
  deleteTaskTree,
  deleteTaskComment,
  findTaskForUser,
  getPopulatedCommentById,
  getPopulatedTaskById,
  listTaskComments,
  listTasksForUser,
  populateTaskQuery,
  updateTask,
  updateTaskComment,
  validateTaskRelations,
};
