const express = require('express');

const {
  deleteUser,
  getCurrentUserProfile,
  getMyPendingInvites,
  getUserById,
  listUsers,
  respondToMyInvite,
  updateCurrentUserProfile,
  updateUserRole,
} = require('../controllers/userController');
const {
  authorizeSystemRoles,
  protect,
} = require('../middlewares/authMiddleware');

const router = express.Router();

router.get('/me', protect, getCurrentUserProfile);
router.patch('/me', protect, updateCurrentUserProfile);
router.get('/me/invites', protect, getMyPendingInvites);
router.patch('/me/invites/:inviteId', protect, respondToMyInvite);

router.get('/', protect, authorizeSystemRoles('admin'), listUsers);
router.get('/:userId', protect, authorizeSystemRoles('admin'), getUserById);
router.patch(
  '/:userId/role',
  protect,
  authorizeSystemRoles('admin'),
  updateUserRole,
);
router.delete('/:userId', protect, authorizeSystemRoles('admin'), deleteUser);

module.exports = router;
