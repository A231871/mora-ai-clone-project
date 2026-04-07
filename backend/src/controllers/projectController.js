const asyncHandler = require('../utils/asyncHandler');
const ApiError = require('../utils/apiError');
const {
  addProjectMember,
  createProjectInvite,
  createProjectTag,
  createProjectWithDefaults,
  deleteProject,
  deleteProjectTag,
  getProjectAccess,
  listProjectInvites,
  listProjectMembers,
  listProjectTags,
  listProjectsForUser,
  removeProjectMember,
  serializeProjectForUser,
  updateProject,
  updateProjectMember,
  updateProjectTag,
} = require('../services/project.service');

const listProjects = asyncHandler(async (req, res) => {
  const projects = await listProjectsForUser(req.user);
  res.status(200).json({
    success: true,
    data: projects,
  });
});

const createProject = asyncHandler(async (req, res) => {
  const { name, description, visibility } = req.body;

  if (!name) {
    throw new ApiError(400, 'name is required');
  }

  const project = await createProjectWithDefaults(req.user, {
    name,
    description,
    visibility,
  });

  res.status(201).json({
    success: true,
    data: project,
  });
});

const getProject = asyncHandler(async (req, res) => {
  const access = await getProjectAccess(req.user, req.params.projectId);
  res.status(200).json({
    success: true,
    data: serializeProjectForUser(req.user, access.project, access),
  });
});

const patchProject = asyncHandler(async (req, res) => {
  const project = await updateProject(req.user, req.params.projectId, req.body);
  res.status(200).json({
    success: true,
    data: project,
  });
});

const destroyProject = asyncHandler(async (req, res) => {
  await deleteProject(req.user, req.params.projectId);
  res.status(200).json({
    success: true,
    message: 'Project deleted successfully',
  });
});

const getProjectMembers = asyncHandler(async (req, res) => {
  const members = await listProjectMembers(req.user, req.params.projectId);
  res.status(200).json({
    success: true,
    data: members,
  });
});

const createProjectMember = asyncHandler(async (req, res) => {
  const member = await addProjectMember(req.user, req.params.projectId, req.body);
  res.status(201).json({
    success: true,
    data: member,
  });
});

const getProjectInvites = asyncHandler(async (req, res) => {
  const invites = await listProjectInvites(req.user, req.params.projectId);
  res.status(200).json({
    success: true,
    data: invites,
  });
});

const createInvite = asyncHandler(async (req, res) => {
  const invite = await createProjectInvite(req.user, req.params.projectId, req.body);
  res.status(201).json({
    success: true,
    data: invite,
  });
});

const patchProjectMember = asyncHandler(async (req, res) => {
  const member = await updateProjectMember(
    req.user,
    req.params.projectId,
    req.params.memberId,
    req.body,
  );
  res.status(200).json({
    success: true,
    data: member,
  });
});

const destroyProjectMember = asyncHandler(async (req, res) => {
  await removeProjectMember(req.user, req.params.projectId, req.params.memberId);
  res.status(200).json({
    success: true,
    message: 'Project member removed successfully',
  });
});

const getProjectTags = asyncHandler(async (req, res) => {
  const tags = await listProjectTags(req.user, req.params.projectId);
  res.status(200).json({
    success: true,
    data: tags,
  });
});

const createTag = asyncHandler(async (req, res) => {
  const tag = await createProjectTag(req.user, req.params.projectId, req.body);
  res.status(201).json({
    success: true,
    data: tag,
  });
});

const patchTag = asyncHandler(async (req, res) => {
  const tag = await updateProjectTag(
    req.user,
    req.params.projectId,
    req.params.tagId,
    req.body,
  );
  res.status(200).json({
    success: true,
    data: tag,
  });
});

const destroyTag = asyncHandler(async (req, res) => {
  await deleteProjectTag(req.user, req.params.projectId, req.params.tagId);
  res.status(200).json({
    success: true,
    message: 'Tag deleted successfully',
  });
});

module.exports = {
  createProject,
  createInvite,
  createProjectMember,
  createTag,
  destroyProject,
  destroyProjectMember,
  destroyTag,
  getProject,
  getProjectInvites,
  getProjectMembers,
  getProjectTags,
  listProjects,
  patchProject,
  patchProjectMember,
  patchTag,
};
