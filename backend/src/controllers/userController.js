const User = require('../models/User');
const asyncHandler = require('../utils/asyncHandler');
const ApiError = require('../utils/apiError');
const { sanitizeUser } = require('../services/auth.service');
const {
  listUserPendingInvites,
  respondToProjectInvite,
} = require('../services/project.service');

const getCurrentUserProfile = asyncHandler(async (req, res) => {
  res.status(200).json({
    success: true,
    data: sanitizeUser(req.user),
  });
});

const updateCurrentUserProfile = asyncHandler(async (req, res) => {
  const { email, profile, avatarConfig, avatarAssetId } = req.body;

  // Email mutation is intentionally blocked until verification/recovery flows exist.
  if (email !== undefined && email !== req.user.email) {
    throw new ApiError(
      400,
      'Email cannot be changed yet while verification support is unavailable',
    );
  }

  if (profile) {
    req.user.profile = {
      displayName:
        profile.displayName !== undefined
          ? profile.displayName
          : req.user.profile.displayName,
      bio: profile.bio !== undefined ? profile.bio : req.user.profile.bio,
    };
  }

  if (avatarConfig) {
    // Avatar config is merged so the frontend can update only the changed parts
    // of the avatar builder instead of resending the entire object every time.
    req.user.avatarConfig = {
      ...req.user.avatarConfig.toObject?.(),
      ...avatarConfig,
    };
  }

  if (avatarAssetId !== undefined) {
    req.user.avatarAssetId = avatarAssetId || null;
  }

  await req.user.save();

  res.status(200).json({
    success: true,
    message: 'Profile updated successfully',
    data: sanitizeUser(req.user),
  });
});

const getMyPendingInvites = asyncHandler(async (req, res) => {
  const invites = await listUserPendingInvites(req.user);
  res.status(200).json({
    success: true,
    data: invites,
  });
});

const respondToMyInvite = asyncHandler(async (req, res) => {
  // Invite acceptance is routed through the same project membership rules used elsewhere.
  const invite = await respondToProjectInvite(
    req.user,
    req.params.inviteId,
    req.body.action,
  );

  res.status(200).json({
    success: true,
    data: invite,
  });
});

const listUsers = asyncHandler(async (req, res) => {
  const query = {};
  if (req.query.q) {
    query.$or = [
      { username: { $regex: req.query.q, $options: 'i' } },
      { email: { $regex: req.query.q, $options: 'i' } },
    ];
  }

  const users = await User.find(query)
    .select('-password')
    .sort({ createdAt: 1 })
    .lean();

  res.status(200).json({
    success: true,
    data: users.map((user) => sanitizeUser(user)),
  });
});

const getUserById = asyncHandler(async (req, res) => {
  const user = await User.findById(req.params.userId).select('-password');
  if (!user) {
    throw new ApiError(404, 'User not found');
  }

  res.status(200).json({
    success: true,
    data: sanitizeUser(user),
  });
});

const updateUserRole = asyncHandler(async (req, res) => {
  const { systemRole } = req.body;
  if (!['admin', 'member'].includes(systemRole)) {
    throw new ApiError(400, 'systemRole must be admin or member');
  }

  const user = await User.findById(req.params.userId);
  if (!user) {
    throw new ApiError(404, 'User not found');
  }

  if (user.systemRole === 'admin' && systemRole === 'member') {
    const adminCount = await User.countDocuments({ systemRole: 'admin' });
    if (adminCount <= 1) {
      throw new ApiError(400, 'At least one admin must remain in the system');
    }
  }

  user.systemRole = systemRole;
  await user.save();

  res.status(200).json({
    success: true,
    message: 'User role updated successfully',
    data: sanitizeUser(user),
  });
});

const deleteUser = asyncHandler(async (req, res) => {
  const user = await User.findById(req.params.userId);
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

  res.status(200).json({
    success: true,
    message: 'User deleted successfully',
  });
});

module.exports = {
  deleteUser,
  getCurrentUserProfile,
  getMyPendingInvites,
  getUserById,
  listUsers,
  respondToMyInvite,
  updateCurrentUserProfile,
  updateUserRole,
};
