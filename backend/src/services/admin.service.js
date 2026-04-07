const bcrypt = require('bcrypt');
const mongoose = require('mongoose');

const FileAsset = require('../models/FileAsset');
const Project = require('../models/Project');
const ProjectInvite = require('../models/ProjectInvite');
const ProjectMember = require('../models/ProjectMember');
const Reminder = require('../models/Reminder');
const Tag = require('../models/Tag');
const Task = require('../models/Task');
const User = require('../models/User');
const ApiError = require('../utils/apiError');
const { sanitizeUser } = require('./auth.service');
const {
  deleteProjectTree,
  ensureNotRemovingLastOwner,
  populateInviteQuery,
} = require('./project.service');
const { createReminder } = require('./reminder.service');
const {
  applyTaskLifecycleState,
  buildInitialTaskLifecycleState,
  deleteTaskTree,
  normalizeEstimatedMinutes,
  normalizeOptionalDate,
  validateTaskRelations,
} = require('./task.service');
const {
  attachTaskToFile,
  buildPublicFileUrl,
  detachTaskFromFile,
  getFileAttachedTaskIds,
  inferFileKind,
  removePhysicalFiles,
} = require('./file.service');

const USER_POPULATE_FIELDS =
  'username email googleId systemRole profile avatarConfig avatarAssetId lastLoginAt createdAt updatedAt';
const PROJECT_POPULATE_FIELDS =
  'name description visibility createdBy archivedAt createdAt updatedAt';
const TASK_OWNER_POPULATE_FIELDS =
  'title projectId status priority createdAt updatedAt';
const FILE_POPULATE_FIELDS =
  'kind originalName publicUrl ownerType ownerId taskIds mimeType size attachedAt createdAt updatedAt';
const DEFAULT_PROJECT_TAGS = [
  { name: 'General', color: '#38bdf8' },
  { name: 'Urgent', color: '#fb7185' },
  { name: 'AI', color: '#a78bfa' },
];

const toObjectIdList = (values = []) => [
  ...new Set((Array.isArray(values) ? values : []).filter(Boolean).map(String)),
];

const trimOrNull = (value) => {
  if (value === undefined || value === null) {
    return null;
  }

  const normalized = value.toString().trim();
  return normalized.length === 0 ? null : normalized;
};

const applyTextSearch = (query, q, fields) => {
  const normalized = trimOrNull(q);
  if (!normalized) {
    return;
  }

  query.$or = fields.map((field) => ({
    [field]: { $regex: normalized, $options: 'i' },
  }));
};

const ensureObjectId = (value, fieldName) => {
  if (!value || !mongoose.Types.ObjectId.isValid(value)) {
    throw new ApiError(400, `${fieldName} is invalid`);
  }

  return value;
};

const ensureSystemRole = (systemRole) => {
  if (systemRole !== undefined && !['admin', 'member'].includes(systemRole)) {
    throw new ApiError(400, 'systemRole must be admin or member');
  }
};

const populateAdminTaskQuery = (query) =>
  query
    .populate('assigneeIds', USER_POPULATE_FIELDS)
    .populate('tagIds', 'name color projectId createdBy createdAt updatedAt')
    .populate('fileIds', FILE_POPULATE_FIELDS)
    .populate('projectId', PROJECT_POPULATE_FIELDS)
    .populate('createdBy', USER_POPULATE_FIELDS)
    .populate('updatedBy', USER_POPULATE_FIELDS);

const populateAdminTagQuery = (query) =>
  query
    .populate('projectId', PROJECT_POPULATE_FIELDS)
    .populate('createdBy', USER_POPULATE_FIELDS);

const populateAdminReminderQuery = (query) =>
  query
    .populate('userId', USER_POPULATE_FIELDS)
    .populate('projectId', PROJECT_POPULATE_FIELDS)
    .populate('taskId', TASK_OWNER_POPULATE_FIELDS);

const ensureUserExists = async (userId, fieldName = 'userId') => {
  ensureObjectId(userId, fieldName);
  const user = await User.findById(userId);
  if (!user) {
    throw new ApiError(404, `${fieldName} user not found`);
  }
  return user;
};

const ensureProjectExists = async (projectId) => {
  ensureObjectId(projectId, 'projectId');
  const project = await Project.findById(projectId);
  if (!project) {
    throw new ApiError(404, 'Project not found');
  }
  return project;
};

const ensureTaskExists = async (taskId) => {
  ensureObjectId(taskId, 'taskId');
  const task = await Task.findById(taskId);
  if (!task) {
    throw new ApiError(404, 'Task not found');
  }
  return task;
};

const ensureFileOwnerTarget = async (ownerType, ownerId) => {
  if (!ownerType || ownerType === 'unassigned') {
    return null;
  }

  if (!ownerId) {
    throw new ApiError(400, 'ownerId is required unless ownerType is unassigned');
  }

  if (ownerType === 'user') {
    return ensureUserExists(ownerId, 'ownerId');
  }

  if (ownerType === 'project') {
    return ensureProjectExists(ownerId);
  }

  if (ownerType === 'task') {
    return ensureTaskExists(ownerId);
  }

  throw new ApiError(400, 'Unsupported ownerType');
};

const enrichProjectsForAdmin = async (projects = []) => {
  if (projects.length === 0) {
    return [];
  }

  const projectIds = projects.map((project) => project._id);
  const [members, invites] = await Promise.all([
    ProjectMember.find({ projectId: { $in: projectIds } })
      .populate('userId', USER_POPULATE_FIELDS)
      .lean(),
    ProjectInvite.find({
      projectId: { $in: projectIds },
      status: 'pending',
    }).lean(),
  ]);

  const memberGroups = new Map();
  for (const member of members) {
    const key = member.projectId.toString();
    const group = memberGroups.get(key) || [];
    group.push(member);
    memberGroups.set(key, group);
  }

  const inviteCountByProjectId = new Map();
  for (const invite of invites) {
    const key = invite.projectId.toString();
    inviteCountByProjectId.set(key, (inviteCountByProjectId.get(key) || 0) + 1);
  }

  return projects.map((project) => {
    const key = project._id.toString();
    const acceptedMembers = memberGroups.get(key) || [];

    return {
      ...project,
      ownerUsers: acceptedMembers
        .filter((member) => member.role === 'owner' && member.userId)
        .map((member) => sanitizeUser(member.userId)),
      acceptedMemberCount: acceptedMembers.length,
      pendingInviteCount: inviteCountByProjectId.get(key) || 0,
    };
  });
};

const loadAdminProject = async (projectId) => {
  const project = await Project.findById(projectId)
    .populate('createdBy', USER_POPULATE_FIELDS)
    .lean();
  if (!project) {
    throw new ApiError(404, 'Project not found');
  }

  const [members, pendingInvites] = await Promise.all([
    ProjectMember.find({ projectId })
      .populate('userId', USER_POPULATE_FIELDS)
      .sort({ createdAt: 1 })
      .lean(),
    populateInviteQuery(
      ProjectInvite.find({ projectId, status: 'pending' }).sort({ createdAt: -1 }),
    ).lean(),
  ]);

  const [enrichedProject] = await enrichProjectsForAdmin([project]);

  return {
    ...enrichedProject,
    members,
    pendingInvites,
  };
};

const decorateFilesWithOwners = async (files = []) => {
  if (files.length === 0) {
    return [];
  }

  const userOwnerIds = [];
  const projectOwnerIds = [];
  const taskOwnerIds = [];

  for (const file of files) {
    if (!file.ownerId) {
      continue;
    }

    if (file.ownerType === 'user') {
      userOwnerIds.push(file.ownerId);
    } else if (file.ownerType === 'project') {
      projectOwnerIds.push(file.ownerId);
    } else if (file.ownerType === 'task') {
      taskOwnerIds.push(file.ownerId);
    }
  }

  const [users, projects, tasks] = await Promise.all([
    userOwnerIds.length > 0
      ? User.find({ _id: { $in: userOwnerIds } }).select(USER_POPULATE_FIELDS).lean()
      : [],
    projectOwnerIds.length > 0
      ? Project.find({ _id: { $in: projectOwnerIds } })
          .select(PROJECT_POPULATE_FIELDS)
          .lean()
      : [],
    taskOwnerIds.length > 0
      ? Task.find({ _id: { $in: taskOwnerIds } })
          .select(TASK_OWNER_POPULATE_FIELDS)
          .lean()
      : [],
  ]);

  const userMap = new Map(users.map((user) => [user._id.toString(), sanitizeUser(user)]));
  const projectMap = new Map(projects.map((project) => [project._id.toString(), project]));
  const taskMap = new Map(tasks.map((task) => [task._id.toString(), task]));

  return files.map((file) => ({
    ...file,
    ownerUser:
      file.ownerType === 'user' && file.ownerId
        ? userMap.get(file.ownerId.toString()) || null
        : null,
    ownerProject:
      file.ownerType === 'project' && file.ownerId
        ? projectMap.get(file.ownerId.toString()) || null
        : null,
    ownerTask:
      file.ownerType === 'task' && file.ownerId
        ? taskMap.get(file.ownerId.toString()) || null
        : null,
  }));
};

const getAdminFileById = async (fileId) => {
  ensureObjectId(fileId, 'fileId');
  const file = await FileAsset.findById(fileId)
    .populate('uploadedBy', USER_POPULATE_FIELDS)
    .lean();
  if (!file) {
    throw new ApiError(404, 'File not found');
  }

  const [decoratedFile] = await decorateFilesWithOwners([file]);
  return decoratedFile;
};

const ensureUniqueUserFields = async ({
  username,
  email,
  excludeUserId = null,
}) => {
  if (username) {
    const usernameOwner = await User.findOne({
      username,
      ...(excludeUserId ? { _id: { $ne: excludeUserId } } : {}),
    });
    if (usernameOwner) {
      throw new ApiError(400, 'Username is already taken');
    }
  }

  if (email) {
    const emailOwner = await User.findOne({
      email,
      ...(excludeUserId ? { _id: { $ne: excludeUserId } } : {}),
    });
    if (emailOwner) {
      throw new ApiError(400, 'Email is already taken');
    }
  }
};

const listAdminUsers = async (filters = {}) => {
  const query = {};
  applyTextSearch(query, filters.q, ['username', 'email', 'profile.displayName']);

  if (filters.systemRole) {
    query.systemRole = filters.systemRole;
  }

  if (filters.provider === 'google') {
    query.googleId = { $exists: true, $ne: null };
  } else if (filters.provider === 'local') {
    query.password = { $exists: true, $ne: null };
  }

  const users = await User.find(query).sort({ createdAt: 1 }).lean();
  return users.map((user) => sanitizeUser(user));
};

const getAdminUserById = async (userId) => {
  ensureObjectId(userId, 'userId');
  const user = await User.findById(userId).lean();
  if (!user) {
    throw new ApiError(404, 'User not found');
  }
  return sanitizeUser(user);
};

const createAdminUser = async (payload = {}) => {
  const username = trimOrNull(payload.username);
  const password = trimOrNull(payload.password);
  const email = trimOrNull(payload.email)?.toLowerCase() || null;
  const systemRole = payload.systemRole || 'member';

  if (!username || !password) {
    throw new ApiError(400, 'username and password are required');
  }

  ensureSystemRole(systemRole);
  await ensureUniqueUserFields({ username, email });

  const hashedPassword = await bcrypt.hash(password, 10);
  const user = await User.create({
    username,
    email: email || undefined,
    password: hashedPassword,
    systemRole,
    profile: {
      displayName: trimOrNull(payload.displayName) || username,
      bio: trimOrNull(payload.bio) || '',
    },
  });

  return sanitizeUser(user);
};

const updateAdminUser = async (userId, payload = {}) => {
  ensureObjectId(userId, 'userId');
  const user = await User.findById(userId);
  if (!user) {
    throw new ApiError(404, 'User not found');
  }

  const username = trimOrNull(payload.username);
  const email =
    payload.email === undefined
      ? undefined
      : trimOrNull(payload.email)?.toLowerCase() || null;

  ensureSystemRole(payload.systemRole);
  await ensureUniqueUserFields({
    username,
    email,
    excludeUserId: user._id,
  });

  if (payload.systemRole && payload.systemRole !== user.systemRole) {
    if (user.systemRole === 'admin' && payload.systemRole === 'member') {
      const adminCount = await User.countDocuments({ systemRole: 'admin' });
      if (adminCount <= 1) {
        throw new ApiError(400, 'At least one admin must remain in the system');
      }
    }
    user.systemRole = payload.systemRole;
  }

  if (username) {
    user.username = username;
  }

  if (email !== undefined) {
    user.email = email || undefined;
  }

  if (payload.password !== undefined) {
    const nextPassword = trimOrNull(payload.password);
    user.password = nextPassword ? await bcrypt.hash(nextPassword, 10) : null;
  }

  if (payload.displayName !== undefined || payload.bio !== undefined) {
    user.profile = {
      displayName:
        payload.displayName !== undefined
          ? trimOrNull(payload.displayName) || ''
          : user.profile?.displayName || '',
      bio:
        payload.bio !== undefined
          ? trimOrNull(payload.bio) || ''
          : user.profile?.bio || '',
    };
  }

  await user.save();
  return sanitizeUser(user);
};

const deleteAdminUser = async (userId) => {
  ensureObjectId(userId, 'userId');
  const user = await User.findById(userId);
  if (!user) {
    throw new ApiError(404, 'User not found');
  }

  if (user.systemRole === 'admin') {
    const adminCount = await User.countDocuments({ systemRole: 'admin' });
    if (adminCount <= 1) {
      throw new ApiError(400, 'At least one admin must remain in the system');
    }
  }

  await user.deleteOne();
};

const listAdminProjects = async (filters = {}) => {
  const query = {};
  applyTextSearch(query, filters.q, ['name', 'description']);

  if (filters.visibility) {
    query.visibility = filters.visibility;
  }

  if (filters.createdByUserId) {
    query.createdBy = ensureObjectId(filters.createdByUserId, 'createdByUserId');
  }

  if (filters.ownerUserId) {
    const ownerProjectIds = await ProjectMember.find({
      userId: ensureObjectId(filters.ownerUserId, 'ownerUserId'),
      role: 'owner',
    }).distinct('projectId');
    query._id = { $in: ownerProjectIds };
  }

  const projects = await Project.find(query)
    .populate('createdBy', USER_POPULATE_FIELDS)
    .sort({ updatedAt: -1 })
    .lean();

  return enrichProjectsForAdmin(projects);
};

const getAdminProjectById = async (projectId) => loadAdminProject(projectId);

const createAdminProject = async (adminUser, payload = {}) => {
  const name = trimOrNull(payload.name);
  if (!name) {
    throw new ApiError(400, 'name is required');
  }

  const createdByUserId =
    trimOrNull(payload.createdByUserId) || adminUser._id.toString();
  const ownerUserId = trimOrNull(payload.ownerUserId) || createdByUserId;

  await Promise.all([
    ensureUserExists(createdByUserId, 'createdByUserId'),
    ensureUserExists(ownerUserId, 'ownerUserId'),
  ]);

  const session = await mongoose.startSession();
  let createdProjectId = null;

  await session.withTransaction(async () => {
    const [project] = await Project.create(
      [
        {
          name,
          description: trimOrNull(payload.description) || '',
          visibility: payload.visibility || 'private',
          createdBy: createdByUserId,
        },
      ],
      { session },
    );

    createdProjectId = project._id;

    await ProjectMember.create(
      [
        {
          projectId: project._id,
          userId: ownerUserId,
          role: 'owner',
          addedBy: adminUser._id,
        },
      ],
      { session },
    );

    await Tag.insertMany(
      DEFAULT_PROJECT_TAGS.map((tag) => ({
        projectId: project._id,
        name: tag.name,
        color: tag.color,
        createdBy: ownerUserId,
      })),
      { session },
    );
  });

  await session.endSession();
  return loadAdminProject(createdProjectId);
};

const updateAdminProject = async (projectId, payload = {}) => {
  const project = await ensureProjectExists(projectId);

  if (payload.createdByUserId !== undefined) {
    const nextCreatedBy = trimOrNull(payload.createdByUserId);
    if (!nextCreatedBy) {
      throw new ApiError(400, 'createdByUserId cannot be empty');
    }
    await ensureUserExists(nextCreatedBy, 'createdByUserId');
    project.createdBy = nextCreatedBy;
  }

  if (payload.name !== undefined) {
    project.name = trimOrNull(payload.name) || project.name;
  }

  if (payload.description !== undefined) {
    project.description = trimOrNull(payload.description) || '';
  }

  if (payload.visibility !== undefined) {
    project.visibility = payload.visibility;
  }

  await project.save();
  return loadAdminProject(project._id);
};

const deleteAdminProject = async (projectId) => {
  await deleteProjectTree(projectId);
};

const createAdminProjectMember = async (adminUser, projectId, payload = {}) => {
  await ensureProjectExists(projectId);
  const userId = trimOrNull(payload.userId);
  if (!userId) {
    throw new ApiError(400, 'userId is required');
  }

  await ensureUserExists(userId);

  const existingMembership = await ProjectMember.findOne({ projectId, userId });
  if (existingMembership) {
    throw new ApiError(400, 'User is already a member of this project');
  }

  const membership = await ProjectMember.create({
    projectId,
    userId,
    role: payload.role || 'viewer',
    addedBy: adminUser._id,
  });

  return membership.populate('userId', USER_POPULATE_FIELDS);
};

const createAdminProjectInvite = async (adminUser, projectId, payload = {}) => {
  await ensureProjectExists(projectId);

  let targetUser = null;
  if (payload.userId) {
    targetUser = await ensureUserExists(payload.userId);
  } else if (payload.username) {
    const username = trimOrNull(payload.username);
    if (!username) {
      throw new ApiError(400, 'username is required');
    }
    targetUser = await User.findOne({ username });
    if (!targetUser) {
      throw new ApiError(404, 'User not found');
    }
  } else {
    throw new ApiError(400, 'userId or username is required');
  }

  const existingMembership = await ProjectMember.findOne({
    projectId,
    userId: targetUser._id,
  });
  if (existingMembership) {
    throw new ApiError(400, 'User is already a member of this project');
  }

  try {
    const invite = await ProjectInvite.create({
      projectId,
      inviterUserId: adminUser._id,
      inviteeUserId: targetUser._id,
      role: payload.role || 'viewer',
    });

    return populateInviteQuery(ProjectInvite.findById(invite._id));
  } catch (error) {
    if (error?.code === 11000) {
      throw new ApiError(400, 'A pending invite already exists for that user');
    }
    throw error;
  }
};

const updateAdminProjectMember = async (projectId, memberId, payload = {}) => {
  ensureObjectId(memberId, 'memberId');
  const membership = await ensureNotRemovingLastOwner(projectId, memberId, payload.role);
  if (!membership) {
    throw new ApiError(404, 'Project member not found');
  }

  membership.role = payload.role || membership.role;
  await membership.save();
  return membership.populate('userId', USER_POPULATE_FIELDS);
};

const deleteAdminProjectMember = async (projectId, memberId) => {
  ensureObjectId(memberId, 'memberId');
  const membership = await ensureNotRemovingLastOwner(projectId, memberId, null);
  if (!membership) {
    throw new ApiError(404, 'Project member not found');
  }

  await membership.deleteOne();
};

const deleteAdminProjectInvite = async (projectId, inviteId) => {
  ensureObjectId(inviteId, 'inviteId');
  const invite = await ProjectInvite.findOne({
    _id: inviteId,
    projectId,
    status: 'pending',
  });
  if (!invite) {
    throw new ApiError(404, 'Pending invite not found');
  }

  await invite.deleteOne();
};

const listAdminTasks = async (filters = {}) => {
  const query = {};
  applyTextSearch(query, filters.q, ['title', 'description']);

  if (filters.projectId) {
    query.projectId = ensureObjectId(filters.projectId, 'projectId');
  }

  if (filters.status) {
    query.status = filters.status;
  }

  if (filters.priority) {
    query.priority = filters.priority;
  }

  if (filters.assigneeId) {
    query.assigneeIds = ensureObjectId(filters.assigneeId, 'assigneeId');
  }

  if (filters.createdByUserId) {
    query.createdBy = ensureObjectId(filters.createdByUserId, 'createdByUserId');
  }

  return populateAdminTaskQuery(Task.find(query).sort({ updatedAt: -1 })).lean();
};

const getAdminTask = async (taskId) => {
  ensureObjectId(taskId, 'taskId');
  const task = await populateAdminTaskQuery(Task.findById(taskId));
  if (!task) {
    throw new ApiError(404, 'Task not found');
  }
  return task.toObject();
};

const createAdminTask = async (adminUser, payload = {}) => {
  const projectId = trimOrNull(payload.projectId);
  const title = trimOrNull(payload.title);
  if (!projectId || !title) {
    throw new ApiError(400, 'projectId and title are required');
  }

  await ensureProjectExists(projectId);

  const createdByUserId =
    trimOrNull(payload.createdByUserId) || adminUser._id.toString();
  const updatedByUserId =
    trimOrNull(payload.updatedByUserId) || createdByUserId;
  const reminderUserId =
    trimOrNull(payload.reminderUserId) || createdByUserId;

  await Promise.all([
    ensureUserExists(createdByUserId, 'createdByUserId'),
    ensureUserExists(updatedByUserId, 'updatedByUserId'),
    ensureUserExists(reminderUserId, 'reminderUserId'),
  ]);

  const session = await mongoose.startSession();
  let createdTaskId = null;

  await session.withTransaction(async () => {
    const relationData = await validateTaskRelations({
      projectId,
      assigneeIds: payload.assigneeIds,
      tagIds: payload.tagIds,
      session,
    });

    const fileIds = toObjectIdList(payload.fileIds);
    let filesToAttach = [];
    if (fileIds.length > 0) {
      filesToAttach = await FileAsset.find({ _id: { $in: fileIds } }).session(
        session,
      );
      if (filesToAttach.length !== fileIds.length) {
        throw new ApiError(400, 'One or more fileIds are invalid');
      }
    }

    const status = payload.status || 'todo';
    const lifecycleState = buildInitialTaskLifecycleState(status);
    const [task] = await Task.create(
      [
        {
          projectId,
          title,
          description: trimOrNull(payload.description) || '',
          status,
          priority: payload.priority || 'medium',
          dueDate: normalizeOptionalDate(payload.dueDate, 'dueDate') ?? null,
          estimatedMinutes:
            normalizeEstimatedMinutes(payload.estimatedMinutes) ?? null,
          startedAt: lifecycleState.startedAt,
          completedAt: lifecycleState.completedAt,
          assigneeIds: relationData.assigneeIds,
          tagIds: relationData.tagIds,
          fileIds,
          createdBy: createdByUserId,
          updatedBy: updatedByUserId,
        },
      ],
      { session },
    );

    createdTaskId = task._id;

    if (payload.reminderAt) {
      const reminder = await createReminder({
        userId: reminderUserId,
        payload: {
          message: trimOrNull(payload.reminderMessage) || title,
          scheduledTime: payload.reminderAt,
          projectId,
          taskId: task._id,
        },
        session,
      });

      task.reminderAt = reminder.scheduledTime;
      task.reminderId = reminder._id;
    }

    if (fileIds.length > 0) {
      for (const file of filesToAttach) {
        attachTaskToFile(file, task._id);
        await file.save({ session });
      }
    }

    await task.save({ session });
  });

  await session.endSession();
  return getAdminTask(createdTaskId);
};

const updateAdminTask = async (adminUser, taskId, payload = {}) => {
  const task = await ensureTaskExists(taskId);

  if (
    payload.projectId !== undefined &&
    payload.projectId.toString() !== task.projectId.toString()
  ) {
    throw new ApiError(400, 'Changing a task project is not supported yet');
  }

  const updaterUserId =
    trimOrNull(payload.updatedByUserId) || adminUser._id.toString();
  const reminderUserId =
    trimOrNull(payload.reminderUserId) ||
    trimOrNull(payload.createdByUserId) ||
    task.createdBy.toString();

  await Promise.all([
    ensureUserExists(updaterUserId, 'updatedByUserId'),
    ensureUserExists(reminderUserId, 'reminderUserId'),
  ]);

  if (payload.createdByUserId !== undefined) {
    await ensureUserExists(payload.createdByUserId, 'createdByUserId');
    task.createdBy = payload.createdByUserId;
  }

  const session = await mongoose.startSession();
  await session.withTransaction(async () => {
    const previousStatus = task.status;
    const relationData = await validateTaskRelations({
      projectId: task.projectId,
      assigneeIds:
        payload.assigneeIds !== undefined ? payload.assigneeIds : task.assigneeIds,
      tagIds: payload.tagIds !== undefined ? payload.tagIds : task.tagIds,
      session,
    });

    if (payload.title !== undefined) {
      task.title = trimOrNull(payload.title) || task.title;
    }

    if (payload.description !== undefined) {
      task.description = trimOrNull(payload.description) || '';
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
    task.updatedBy = updaterUserId;

    if (payload.fileIds !== undefined) {
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
        const attachFiles = touchedFiles.filter((file) =>
          toAttach.includes(file._id.toString()),
        );
        if (attachFiles.length !== toAttach.length) {
          throw new ApiError(400, 'One or more fileIds are invalid');
        }
      }

      if (touchedFiles.length > 0) {
        for (const file of touchedFiles) {
          if (toAttach.includes(file._id.toString())) {
            attachTaskToFile(file, task._id);
          } else if (toDetach.includes(file._id.toString())) {
            detachTaskFromFile(file, task._id);
          }
          await file.save({ session });
        }
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
          reminder.userId = reminderUserId;
          reminder.message =
            trimOrNull(payload.reminderMessage) || task.title;
          reminder.scheduledTime = new Date(payload.reminderAt);
          reminder.projectId = task.projectId;
          reminder.taskId = task._id;
          reminder.isCompleted = false;
          await reminder.save({ session });
          task.reminderAt = reminder.scheduledTime;
        }
      } else {
        const reminder = await createReminder({
          userId: reminderUserId,
          payload: {
            message: trimOrNull(payload.reminderMessage) || task.title,
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
  return getAdminTask(task._id);
};

const deleteAdminTask = async (taskId) => {
  const task = await ensureTaskExists(taskId);
  await deleteTaskTree(task);
};

const listAdminTags = async (filters = {}) => {
  const query = {};
  applyTextSearch(query, filters.q, ['name', 'color']);

  if (filters.projectId) {
    query.projectId = ensureObjectId(filters.projectId, 'projectId');
  }

  if (filters.createdByUserId) {
    query.createdBy = ensureObjectId(filters.createdByUserId, 'createdByUserId');
  }

  return populateAdminTagQuery(Tag.find(query).sort({ createdAt: -1 })).lean();
};

const getAdminTag = async (tagId) => {
  ensureObjectId(tagId, 'tagId');
  const tag = await populateAdminTagQuery(Tag.findById(tagId));
  if (!tag) {
    throw new ApiError(404, 'Tag not found');
  }
  return tag.toObject();
};

const createAdminTag = async (adminUser, payload = {}) => {
  const projectId = trimOrNull(payload.projectId);
  const name = trimOrNull(payload.name);
  if (!projectId || !name) {
    throw new ApiError(400, 'projectId and name are required');
  }

  await ensureProjectExists(projectId);
  const createdByUserId =
    trimOrNull(payload.createdByUserId) || adminUser._id.toString();
  await ensureUserExists(createdByUserId, 'createdByUserId');

  const tag = await Tag.create({
    projectId,
    name,
    color: trimOrNull(payload.color) || '#7dd3fc',
    createdBy: createdByUserId,
  });

  return getAdminTag(tag._id);
};

const updateAdminTag = async (tagId, payload = {}) => {
  ensureObjectId(tagId, 'tagId');
  const tag = await Tag.findById(tagId);
  if (!tag) {
    throw new ApiError(404, 'Tag not found');
  }

  if (payload.projectId !== undefined) {
    const nextProjectId = trimOrNull(payload.projectId);
    if (!nextProjectId) {
      throw new ApiError(400, 'projectId cannot be empty');
    }
    await ensureProjectExists(nextProjectId);
    tag.projectId = nextProjectId;
  }

  if (payload.createdByUserId !== undefined) {
    const nextCreatedBy = trimOrNull(payload.createdByUserId);
    if (!nextCreatedBy) {
      throw new ApiError(400, 'createdByUserId cannot be empty');
    }
    await ensureUserExists(nextCreatedBy, 'createdByUserId');
    tag.createdBy = nextCreatedBy;
  }

  if (payload.name !== undefined) {
    tag.name = trimOrNull(payload.name) || tag.name;
  }

  if (payload.color !== undefined) {
    tag.color = trimOrNull(payload.color) || '#7dd3fc';
  }

  await tag.save();
  return getAdminTag(tag._id);
};

const deleteAdminTag = async (tagId) => {
  ensureObjectId(tagId, 'tagId');
  const tag = await Tag.findById(tagId);
  if (!tag) {
    throw new ApiError(404, 'Tag not found');
  }

  await Task.updateMany({ tagIds: tag._id }, { $pull: { tagIds: tag._id } });
  await tag.deleteOne();
};

const listAdminFiles = async (filters = {}) => {
  const query = {};
  applyTextSearch(query, filters.q, ['originalName', 'mimeType']);

  if (filters.ownerType) {
    if (filters.ownerType !== 'task') {
      query.ownerType = filters.ownerType;
    }
  }

  if (filters.ownerId) {
    const normalizedOwnerId = ensureObjectId(filters.ownerId, 'ownerId');
    if (filters.ownerType === 'task') {
      const taskOwnerQuery = {
        $or: [
        { ownerType: 'task', ownerId: normalizedOwnerId },
        { taskIds: normalizedOwnerId },
        ],
      };

      if (query.$or) {
        query.$and = [{ $or: query.$or }, taskOwnerQuery];
        delete query.$or;
      } else {
        Object.assign(query, taskOwnerQuery);
      }
    } else {
      query.ownerId = normalizedOwnerId;
    }
  }

  if (filters.kind) {
    query.kind = filters.kind;
  }

  if (filters.uploadedByUserId) {
    query.uploadedBy = ensureObjectId(filters.uploadedByUserId, 'uploadedByUserId');
  }

  const files = await FileAsset.find(query)
    .populate('uploadedBy', USER_POPULATE_FIELDS)
    .sort({ createdAt: -1 })
    .lean();

  return decorateFilesWithOwners(files);
};

const createAdminFile = async (req, adminUser) => {
  if (!req.file) {
    throw new ApiError(400, 'file is required');
  }

  const ownerType = req.body.ownerType || 'unassigned';
  const ownerId = trimOrNull(req.body.ownerId);
  const inferredKind = inferFileKind(req.file);
  const kind = req.body.kind || inferredKind;
  const uploadedByUserId =
    trimOrNull(req.body.uploadedByUserId) || adminUser._id.toString();

  if (!kind || !inferredKind || kind !== inferredKind) {
    removePhysicalFiles([req.file.path]);
    throw new ApiError(400, 'Unsupported file kind');
  }

  if (ownerType !== 'unassigned') {
    await ensureFileOwnerTarget(ownerType, ownerId);
  }

  await ensureUserExists(uploadedByUserId, 'uploadedByUserId');

  const fileAsset = await FileAsset.create({
    uploadedBy: uploadedByUserId,
    ownerType,
    ownerId,
    taskIds: ownerType === 'task' && ownerId ? [ownerId] : [],
    kind,
    originalName: req.file.originalname,
    storedName: req.file.filename,
    mimeType: req.file.mimetype,
    size: req.file.size,
    storagePath: req.file.path,
    publicUrl: buildPublicFileUrl(req, req.file.filename),
    attachedAt: ownerType === 'unassigned' ? null : new Date(),
  });

  if (ownerType === 'task' && ownerId) {
    await Task.updateOne({ _id: ownerId }, { $addToSet: { fileIds: fileAsset._id } });
  }

  return getAdminFileById(fileAsset._id);
};

const updateAdminFile = async (fileId, payload = {}) => {
  const fileAsset = await FileAsset.findById(fileId);
  if (!fileAsset) {
    throw new ApiError(404, 'File not found');
  }

  const nextOwnerType = payload.ownerType ?? fileAsset.ownerType;
  const nextOwnerId =
    payload.ownerId !== undefined
      ? trimOrNull(payload.ownerId)
      : fileAsset.ownerId?.toString() || null;

  if (nextOwnerType !== 'unassigned') {
    await ensureFileOwnerTarget(nextOwnerType, nextOwnerId);
  }

  if (payload.uploadedByUserId !== undefined) {
    const uploadedByUserId = trimOrNull(payload.uploadedByUserId);
    if (!uploadedByUserId) {
      throw new ApiError(400, 'uploadedByUserId cannot be empty');
    }
    await ensureUserExists(uploadedByUserId, 'uploadedByUserId');
    fileAsset.uploadedBy = uploadedByUserId;
  }

  if (payload.originalName !== undefined) {
    fileAsset.originalName =
      trimOrNull(payload.originalName) || fileAsset.originalName;
  }

  const ownerChanged =
    nextOwnerType !== fileAsset.ownerType ||
    (nextOwnerId || null) !== (fileAsset.ownerId?.toString() || null);

  if (ownerChanged) {
    const previousTaskIds = getFileAttachedTaskIds(fileAsset);
    if (previousTaskIds.length > 0) {
      await Task.updateMany(
        { _id: { $in: previousTaskIds } },
        { $pull: { fileIds: fileAsset._id } },
      );
    }

    fileAsset.ownerType = nextOwnerType;
    fileAsset.ownerId = nextOwnerType === 'unassigned' ? null : nextOwnerId;
    fileAsset.taskIds = nextOwnerType === 'task' && nextOwnerId ? [nextOwnerId] : [];
    fileAsset.attachedAt =
      nextOwnerType === 'unassigned' ? null : fileAsset.attachedAt || new Date();

    const nextTaskIds = getFileAttachedTaskIds(fileAsset);
    if (nextTaskIds.length > 0) {
      await Task.updateMany(
        { _id: { $in: nextTaskIds } },
        { $addToSet: { fileIds: fileAsset._id } },
      );
    }
  }

  await fileAsset.save();
  return getAdminFileById(fileAsset._id);
};

const deleteAdminFile = async (fileId) => {
  const fileAsset = await FileAsset.findById(fileId);
  if (!fileAsset) {
    throw new ApiError(404, 'File not found');
  }

  const linkedTaskIds = getFileAttachedTaskIds(fileAsset);
  if (linkedTaskIds.length > 0) {
    await Task.updateMany(
      { _id: { $in: linkedTaskIds } },
      { $pull: { fileIds: fileAsset._id } },
    );
  }

  const storagePath = fileAsset.storagePath;
  await fileAsset.deleteOne();
  removePhysicalFiles([storagePath]);
};

const listAdminReminders = async (filters = {}) => {
  const query = {};
  applyTextSearch(query, filters.q, ['message']);

  if (filters.userId) {
    query.userId = ensureObjectId(filters.userId, 'userId');
  }

  if (filters.projectId) {
    query.projectId = ensureObjectId(filters.projectId, 'projectId');
  }

  if (filters.taskId) {
    query.taskId = ensureObjectId(filters.taskId, 'taskId');
  }

  if (filters.isCompleted !== undefined) {
    query.isCompleted = Boolean(filters.isCompleted);
  }

  return populateAdminReminderQuery(
    Reminder.find(query).sort({ scheduledTime: 1 }),
  ).lean();
};

const getAdminReminder = async (reminderId) => {
  ensureObjectId(reminderId, 'reminderId');
  const reminder = await populateAdminReminderQuery(Reminder.findById(reminderId));
  if (!reminder) {
    throw new ApiError(404, 'Reminder not found');
  }
  return reminder.toObject();
};

const createAdminReminder = async (payload = {}) => {
  const userId = trimOrNull(payload.userId);
  if (!userId) {
    throw new ApiError(400, 'userId is required');
  }

  await ensureUserExists(userId);

  if (payload.projectId) {
    await ensureProjectExists(payload.projectId);
  }

  if (payload.taskId) {
    await ensureTaskExists(payload.taskId);
  }

  const reminder = await createReminder({
    userId,
    payload,
  });

  return getAdminReminder(reminder._id);
};

const updateAdminReminder = async (reminderId, payload = {}) => {
  ensureObjectId(reminderId, 'reminderId');
  const reminder = await Reminder.findById(reminderId);
  if (!reminder) {
    throw new ApiError(404, 'Reminder not found');
  }

  if (payload.userId !== undefined) {
    const userId = trimOrNull(payload.userId);
    if (!userId) {
      throw new ApiError(400, 'userId cannot be empty');
    }
    await ensureUserExists(userId);
    reminder.userId = userId;
  }

  if (payload.projectId !== undefined) {
    const projectId = trimOrNull(payload.projectId);
    if (projectId) {
      await ensureProjectExists(projectId);
    }
    reminder.projectId = projectId || null;
  }

  if (payload.taskId !== undefined) {
    const taskId = trimOrNull(payload.taskId);
    if (taskId) {
      await ensureTaskExists(taskId);
    }
    reminder.taskId = taskId || null;
  }

  const touchedScheduleFields =
    payload.task !== undefined ||
    payload.message !== undefined ||
    payload.scheduledTime !== undefined ||
    payload.daysOfWeek !== undefined ||
    payload.projectId !== undefined ||
    payload.taskId !== undefined;

  if (payload.task !== undefined || payload.message !== undefined) {
    reminder.message =
      trimOrNull(payload.task) || trimOrNull(payload.message) || reminder.message;
  }

  if (payload.scheduledTime !== undefined) {
    const scheduledTime = new Date(payload.scheduledTime);
    if (Number.isNaN(scheduledTime.getTime())) {
      throw new ApiError(400, 'scheduledTime is invalid');
    }
    reminder.scheduledTime = scheduledTime;
  }

  if (payload.daysOfWeek !== undefined) {
    reminder.daysOfWeek = Array.isArray(payload.daysOfWeek)
      ? payload.daysOfWeek
      : [];
  }

  if (payload.isCompleted !== undefined) {
    reminder.isCompleted = payload.isCompleted;
  } else if (touchedScheduleFields) {
    reminder.isCompleted = false;
  }

  await reminder.save();

  return getAdminReminder(reminder._id);
};

const deleteAdminReminder = async (reminderId) => {
  ensureObjectId(reminderId, 'reminderId');
  const reminder = await Reminder.findById(reminderId);
  if (!reminder) {
    throw new ApiError(404, 'Reminder not found');
  }

  await reminder.deleteOne();
};

module.exports = {
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
};
