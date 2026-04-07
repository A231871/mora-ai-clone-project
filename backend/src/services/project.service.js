const mongoose = require('mongoose');

const Project = require('../models/Project');
const ProjectMember = require('../models/ProjectMember');
const FileAsset = require('../models/FileAsset');
const ProjectInvite = require('../models/ProjectInvite');
const Reminder = require('../models/Reminder');
const Tag = require('../models/Tag');
const Task = require('../models/Task');
const TaskComment = require('../models/TaskComment');
const User = require('../models/User');
const ApiError = require('../utils/apiError');
const {
  detachTaskFromFile,
  getFileAttachedTaskIds,
  removePhysicalFiles,
} = require('./file.service');

const PROJECT_ROLE_WEIGHT = {
  viewer: 1,
  editor: 2,
  owner: 3,
};

const DEFAULT_PROJECT_TAGS = [
  { name: 'General', color: '#38bdf8' },
  { name: 'Urgent', color: '#fb7185' },
  { name: 'AI', color: '#a78bfa' },
];

const uniqueObjectIds = (values = []) => [
  ...new Set(values.filter(Boolean).map((value) => value.toString())),
];

const populateInviteQuery = (query) =>
  query
    .populate('projectId', 'name description visibility')
    .populate('inviterUserId', 'username email systemRole profile avatarConfig')
    .populate('inviteeUserId', 'username email systemRole profile avatarConfig');

const toProjectObject = (project) =>
  typeof project?.toObject === 'function' ? project.toObject() : { ...project };

const buildProjectAccessMetadata = ({
  user,
  projectRole = null,
  adminReadOnlyOverride = false,
}) => ({
  currentRole: projectRole,
  adminReadOnlyOverride,
  memberUiReadOnly: Boolean(adminReadOnlyOverride),
});

const serializeProjectForUser = (user, project, access = {}) => ({
  ...toProjectObject(project),
  ...buildProjectAccessMetadata({
    user,
    projectRole: access.projectRole ?? null,
    adminReadOnlyOverride: access.adminReadOnlyOverride ?? false,
  }),
});

const getAccessibleProjectIds = async (user) => {
  const memberProjectIds = await ProjectMember.find({ userId: user._id }).distinct(
    'projectId',
  );

  return uniqueObjectIds(memberProjectIds);
};

const getProjectById = async (projectId) => {
  const project = await Project.findById(projectId);
  if (!project) {
    throw new ApiError(404, 'Project not found');
  }
  return project;
};

const getProjectAccess = async (user, projectId) => {
  const project = await getProjectById(projectId);
  const membership = await ProjectMember.findOne({
    projectId: project._id,
    userId: user._id,
  });

  if (membership) {
    return {
      project,
      projectRole: membership.role,
      membership,
      adminReadOnlyOverride: false,
    };
  }

  throw new ApiError(403, 'You do not have access to this project');
};

const requireProjectRole = async (user, projectId, minimumRole = 'viewer') => {
  const access = await getProjectAccess(user, projectId);
  const currentWeight = PROJECT_ROLE_WEIGHT[access.projectRole] || 0;
  const minimumWeight = PROJECT_ROLE_WEIGHT[minimumRole] || 0;

  if (currentWeight < minimumWeight) {
    throw new ApiError(403, 'You do not have permission for this project action');
  }

  return access;
};

const listProjectsForUser = async (user) => {
  const projectIds = await getAccessibleProjectIds(user);
  const memberships = await ProjectMember.find({ userId: user._id })
    .select('projectId role')
    .lean();
  const roleByProjectId = new Map(
    memberships.map((membership) => [
      membership.projectId.toString(),
      membership.role,
    ]),
  );

  const projects = await Project.find({ _id: { $in: projectIds } })
    .sort({ updatedAt: -1 })
    .lean();

  return projects.map((project) =>
    serializeProjectForUser(user, project, {
      projectRole: roleByProjectId.get(project._id.toString()) || null,
      adminReadOnlyOverride: false,
    }),
  );
};

const createProjectWithDefaults = async (user, payload) => {
  const session = await mongoose.startSession();
  let createdProjectId = null;

  await session.withTransaction(async () => {
    const [project] = await Project.create(
      [
        {
          name: payload.name,
          description: payload.description || '',
          visibility: payload.visibility || 'private',
          createdBy: user._id,
        },
      ],
      { session },
    );

    createdProjectId = project._id;

    await ProjectMember.create(
      [
        {
          projectId: project._id,
          userId: user._id,
          role: 'owner',
          addedBy: user._id,
        },
      ],
      { session },
    );

    await Tag.insertMany(
      DEFAULT_PROJECT_TAGS.map((tag) => ({
        projectId: project._id,
        name: tag.name,
        color: tag.color,
        createdBy: user._id,
      })),
      { session },
    );
  });

  await session.endSession();

  const project = await Project.findById(createdProjectId).lean();
  return serializeProjectForUser(user, project, {
    projectRole: 'owner',
    adminReadOnlyOverride: false,
  });
};

const updateProject = async (user, projectId, payload) => {
  const access = await requireProjectRole(user, projectId, 'owner');
  const { project } = access;
  const allowedFields = ['name', 'description', 'visibility'];

  for (const field of allowedFields) {
    if (payload[field] !== undefined) {
      project[field] = payload[field];
    }
  }

  await project.save();
  return serializeProjectForUser(user, project, access);
};

const deleteProjectTree = async (projectId) => {
  const project = await getProjectById(projectId);
  const storagePaths = [];

  const taskIds = await Task.find({ projectId: project._id }).distinct('_id');
  const taskIdStrings = uniqueObjectIds(taskIds);
  const fileDocs = await FileAsset.find({
    $or: [
      { ownerType: 'project', ownerId: project._id },
      { ownerType: 'task', ownerId: { $in: taskIds } },
      { taskIds: { $in: taskIds } },
    ],
  });

  const fileIdsToDelete = [];
  for (const file of fileDocs) {
    const attachedTaskIds = getFileAttachedTaskIds(file);
    const remainingTaskIds = attachedTaskIds.filter(
      (taskId) => !taskIdStrings.includes(taskId),
    );
    const isProjectOwnedFile =
      file.ownerType === 'project' &&
      file.ownerId?.toString() === project._id.toString();
    const isLegacyProjectTaskFile =
      file.ownerType === 'task' &&
      file.ownerId &&
      taskIdStrings.includes(file.ownerId.toString()) &&
      remainingTaskIds.length === 0;

    if (isProjectOwnedFile || isLegacyProjectTaskFile) {
      storagePaths.push(file.storagePath);
      fileIdsToDelete.push(file._id);
      continue;
    }

    for (const taskId of taskIdStrings) {
      detachTaskFromFile(file, taskId);
    }
    await file.save();
  }

  await project.deleteOne();
  await ProjectMember.deleteMany({ projectId: project._id });
  await Tag.deleteMany({ projectId: project._id });
  await TaskComment.deleteMany({ projectId: project._id });
  await Task.deleteMany({ projectId: project._id });
  await Reminder.deleteMany({ projectId: project._id });
  await ProjectInvite.deleteMany({ projectId: project._id });
  if (fileIdsToDelete.length > 0) {
    await FileAsset.deleteMany({ _id: { $in: fileIdsToDelete } });
  }

  removePhysicalFiles(storagePaths);
};

const deleteProject = async (user, projectId) => {
  await requireProjectRole(user, projectId, 'owner');
  await deleteProjectTree(projectId);
};

const listProjectMembers = async (user, projectId) => {
  await getProjectAccess(user, projectId);
  return ProjectMember.find({ projectId })
    .populate('userId', 'username email systemRole profile avatarConfig')
    .sort({ createdAt: 1 })
    .lean();
};

const addProjectMember = async (user, projectId, payload) => {
  await requireProjectRole(user, projectId, 'owner');

  const targetUser = await User.findById(payload.userId);
  if (!targetUser) {
    throw new ApiError(404, 'Target user not found');
  }

  const existingMembership = await ProjectMember.findOne({
    projectId,
    userId: payload.userId,
  });

  if (existingMembership) {
    throw new ApiError(400, 'User is already a member of this project');
  }

  const membership = await ProjectMember.create({
    projectId,
    userId: payload.userId,
    role: payload.role || 'viewer',
    addedBy: user._id,
  });

  return membership.populate('userId', 'username email systemRole profile avatarConfig');
};

const listProjectInvites = async (user, projectId) => {
  await requireProjectRole(user, projectId, 'owner');
  return populateInviteQuery(
    ProjectInvite.find({ projectId, status: 'pending' }).sort({ createdAt: -1 }),
  ).lean();
};

const createProjectInvite = async (user, projectId, payload) => {
  const { project } = await requireProjectRole(user, projectId, 'owner');
  const username = (payload.username || '').trim();

  if (!username) {
    throw new ApiError(400, 'username is required');
  }

  const targetUser = await User.findOne({ username });
  if (!targetUser) {
    throw new ApiError(404, 'User not found for that username');
  }

  if (targetUser._id.toString() === user._id.toString()) {
    throw new ApiError(400, 'You cannot invite yourself');
  }

  const existingMembership = await ProjectMember.findOne({
    projectId: project._id,
    userId: targetUser._id,
  });

  if (existingMembership) {
    throw new ApiError(400, 'User is already a member of this project');
  }

  try {
    const invite = await ProjectInvite.create({
      projectId: project._id,
      inviterUserId: user._id,
      inviteeUserId: targetUser._id,
      role: payload.role || 'viewer',
    });

    return await populateInviteQuery(ProjectInvite.findById(invite._id));
  } catch (error) {
    if (error?.code === 11000) {
      throw new ApiError(400, 'A pending invite already exists for that user');
    }

    throw error;
  }
};

const listUserPendingInvites = async (user) =>
  populateInviteQuery(
    ProjectInvite.find({
      inviteeUserId: user._id,
      status: 'pending',
    }).sort({ createdAt: -1 }),
  ).lean();

const respondToProjectInvite = async (user, inviteId, action) => {
  if (!['accept', 'decline'].includes(action)) {
    throw new ApiError(400, 'action must be accept or decline');
  }

  const session = await mongoose.startSession();
  let updatedInviteId = null;

  await session.withTransaction(async () => {
    const invite = await ProjectInvite.findOne({
      _id: inviteId,
      inviteeUserId: user._id,
    }).session(session);

    if (!invite) {
      throw new ApiError(404, 'Invite not found');
    }

    if (invite.status !== 'pending') {
      throw new ApiError(400, 'Invite has already been processed');
    }

    updatedInviteId = invite._id;

    if (action === 'accept') {
      const existingMembership = await ProjectMember.findOne({
        projectId: invite.projectId,
        userId: user._id,
      }).session(session);

      if (!existingMembership) {
        await ProjectMember.create(
          [
            {
              projectId: invite.projectId,
              userId: user._id,
              role: invite.role,
              addedBy: invite.inviterUserId,
            },
          ],
          { session },
        );
      }

      invite.status = 'accepted';
    } else {
      invite.status = 'declined';
    }

    invite.respondedAt = new Date();
    await invite.save({ session });
  });

  await session.endSession();

  return await populateInviteQuery(ProjectInvite.findById(updatedInviteId));
};

const ensureNotRemovingLastOwner = async (projectId, memberId, nextRole = null) => {
  const currentMember = await ProjectMember.findOne({
    _id: memberId,
    projectId,
  });

  if (!currentMember || currentMember.role !== 'owner') {
    return currentMember;
  }

  if (nextRole === 'owner') {
    return currentMember;
  }

  const ownerCount = await ProjectMember.countDocuments({
    projectId,
    role: 'owner',
  });

  if (ownerCount <= 1) {
    throw new ApiError(400, 'Project must keep at least one owner');
  }

  return currentMember;
};

const updateProjectMember = async (user, projectId, memberId, payload) => {
  await requireProjectRole(user, projectId, 'owner');
  const membership = await ensureNotRemovingLastOwner(
    projectId,
    memberId,
    payload.role,
  );

  if (!membership) {
    throw new ApiError(404, 'Project member not found');
  }

  membership.role = payload.role || membership.role;
  await membership.save();
  return membership.populate('userId', 'username email systemRole profile avatarConfig');
};

const removeProjectMember = async (user, projectId, memberId) => {
  await requireProjectRole(user, projectId, 'owner');
  const membership = await ensureNotRemovingLastOwner(projectId, memberId, null);

  if (!membership) {
    throw new ApiError(404, 'Project member not found');
  }

  await membership.deleteOne();
};

const listProjectTags = async (user, projectId) => {
  await getProjectAccess(user, projectId);
  return Tag.find({ projectId }).sort({ createdAt: 1 }).lean();
};

const createProjectTag = async (user, projectId, payload) => {
  await requireProjectRole(user, projectId, 'editor');
  return Tag.create({
    projectId,
    name: payload.name,
    color: payload.color || '#7dd3fc',
    createdBy: user._id,
  });
};

const updateProjectTag = async (user, projectId, tagId, payload) => {
  await requireProjectRole(user, projectId, 'editor');

  const tag = await Tag.findOne({ _id: tagId, projectId });
  if (!tag) {
    throw new ApiError(404, 'Tag not found');
  }

  if (payload.name !== undefined) {
    tag.name = payload.name;
  }

  if (payload.color !== undefined) {
    tag.color = payload.color;
  }

  await tag.save();
  return tag;
};

const deleteProjectTag = async (user, projectId, tagId) => {
  await requireProjectRole(user, projectId, 'editor');

  const deleted = await Tag.findOneAndDelete({ _id: tagId, projectId });
  if (!deleted) {
    throw new ApiError(404, 'Tag not found');
  }
};

module.exports = {
  addProjectMember,
  createProjectInvite,
  createProjectTag,
  createProjectWithDefaults,
  deleteProject,
  deleteProjectTree,
  deleteProjectTag,
  ensureNotRemovingLastOwner,
  getAccessibleProjectIds,
  getProjectAccess,
  buildProjectAccessMetadata,
  listProjectInvites,
  listProjectMembers,
  listProjectTags,
  listProjectsForUser,
  listUserPendingInvites,
  populateInviteQuery,
  removeProjectMember,
  respondToProjectInvite,
  requireProjectRole,
  serializeProjectForUser,
  updateProject,
  updateProjectMember,
  updateProjectTag,
};
