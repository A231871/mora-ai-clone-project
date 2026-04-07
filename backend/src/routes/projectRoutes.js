const express = require('express');

const {
  createProject,
  createInvite,
  createProjectMember,
  createTag,
  destroyProject,
  destroyProjectMember,
  destroyTag,
  getAnalyticsOverview,
  getAnalyticsWorkload,
  getProject,
  getProjectInvites,
  getProjectMembers,
  getProjectTags,
  listProjects,
  patchProject,
  patchProjectMember,
  patchTag,
} = require('../controllers/projectController');
const { protect } = require('../middlewares/authMiddleware');

const router = express.Router();

router.use(protect);

router.route('/').get(listProjects).post(createProject);
router.route('/:projectId').get(getProject).patch(patchProject).delete(destroyProject);
router.route('/:projectId/analytics/overview').get(getAnalyticsOverview);
router.route('/:projectId/analytics/workload').get(getAnalyticsWorkload);

router
  .route('/:projectId/members')
  .get(getProjectMembers)
  .post(createProjectMember);
router.route('/:projectId/invites').get(getProjectInvites).post(createInvite);
router
  .route('/:projectId/members/:memberId')
  .patch(patchProjectMember)
  .delete(destroyProjectMember);

router.route('/:projectId/tags').get(getProjectTags).post(createTag);
router.route('/:projectId/tags/:tagId').patch(patchTag).delete(destroyTag);

module.exports = router;
