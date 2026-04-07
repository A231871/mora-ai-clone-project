const bcrypt = require('bcrypt');
const { OAuth2Client } = require('google-auth-library');

const User = require('../models/User');
const asyncHandler = require('../utils/asyncHandler');
const ApiError = require('../utils/apiError');
const {
  buildAuthPayload,
  revokeAllSessionsForUser,
  revokeRefreshToken,
  rotateRefreshToken,
  sanitizeUser,
} = require('../services/auth.service');

const googleOAuthClient = new OAuth2Client();

const getRequestMeta = (req) => ({
  ipAddress: req.ip,
  userAgent: req.get('user-agent') || '',
});

const buildUniqueUsername = async (baseUsername) => {
  // Google accounts can collide on the same email prefix, so we generate
  // a unique username instead of failing the login flow.
  let username = baseUsername;
  let suffix = 0;

  while (await User.findOne({ username })) {
    suffix += 1;
    username = `${baseUsername}_${suffix}`;
  }

  return username;
};

const register = asyncHandler(async (req, res) => {
  const { username, password, email } = req.body;

  if (!username || !password) {
    throw new ApiError(400, 'username and password are required');
  }

  const existingUser = await User.findOne({
    $or: [{ username }, ...(email ? [{ email }] : [])],
  });
  if (existingUser) {
    throw new ApiError(400, 'Username or email already taken');
  }

  const userCount = await User.countDocuments();
  const hashedPassword = await bcrypt.hash(password, 10);

  const newUser = await User.create({
    username,
    email: email || undefined,
    password: hashedPassword,
    // The first registered account is promoted to admin to bootstrap the system.
    systemRole: userCount === 0 ? 'admin' : 'member',
    profile: {
      displayName: username,
      bio: '',
    },
  });

  res.status(201).json({
    success: true,
    message: 'User registered successfully!',
    user: sanitizeUser(newUser),
  });
});

const login = asyncHandler(async (req, res) => {
  const { username, password } = req.body;

  if (!username || !password) {
    throw new ApiError(400, 'username and password are required');
  }

  const user = await User.findOne({ username });
  if (!user) {
    throw new ApiError(400, 'User not found!');
  }

  if (!user.password) {
    throw new ApiError(400, 'This account uses Google sign-in.');
  }

  const isMatch = await bcrypt.compare(password, user.password);
  if (!isMatch) {
    throw new ApiError(400, 'Invalid credentials!');
  }

  user.lastLoginAt = new Date();
  await user.save();

  res.status(200).json(await buildAuthPayload(user, getRequestMeta(req)));
});

const googleLogin = asyncHandler(async (req, res) => {
  const { idToken } = req.body;
  if (!idToken) {
    throw new ApiError(400, 'idToken is required');
  }

  const audience = process.env.GOOGLE_CLIENT_ID;
  if (!audience) {
    throw new ApiError(503, 'Google sign-in is not configured on the server.');
  }

  const ticket = await googleOAuthClient.verifyIdToken({
    idToken,
    audience,
  });
  const payload = ticket.getPayload();
  if (!payload || !payload.sub) {
    throw new ApiError(401, 'Invalid Google token');
  }

  const googleId = payload.sub;
  const email = (payload.email || '').trim().toLowerCase();

  let user = await User.findOne({
    $or: [{ googleId }, ...(email ? [{ email }] : [])],
  });

  if (!user) {
    const baseUsername =
      email && email.includes('@')
        ? email.split('@')[0]
        : `user_${googleId.slice(0, 8)}`;

    const username = await buildUniqueUsername(baseUsername);
    const userCount = await User.countDocuments();

    user = await User.create({
      username,
      email: email || undefined,
      password: null,
      googleId,
      // Google sign-in follows the same bootstrap rule as local registration.
      systemRole: userCount === 0 ? 'admin' : 'member',
      profile: {
        displayName: payload.name || username,
        bio: '',
      },
    });
  } else if (!user.googleId) {
    // Existing local accounts can later be linked to Google without creating duplicates.
    user.googleId = googleId;
  }

  if (email) {
    const currentEmail = (user.email || '').trim().toLowerCase();
    if (!currentEmail) {
      const conflictingEmailUser = await User.findOne({
        _id: { $ne: user._id },
        email,
      });

      if (!conflictingEmailUser) {
        user.email = email;
      }
    }
  }

  user.lastLoginAt = new Date();
  await user.save();

  res.status(200).json(await buildAuthPayload(user, getRequestMeta(req)));
});

const refresh = asyncHandler(async (req, res) => {
  const { refreshToken } = req.body;
  // Refresh requests issue a brand new token pair instead of extending the old one.
  const refreshedSession = await rotateRefreshToken(refreshToken, getRequestMeta(req));
  refreshedSession.user.lastLoginAt = new Date();
  await refreshedSession.user.save();

  res.status(200).json({
    success: true,
    message: 'Token refreshed successfully',
    token: refreshedSession.token,
    refreshToken: refreshedSession.refreshToken,
    avatarConfig: refreshedSession.user.avatarConfig,
    user: sanitizeUser(refreshedSession.user),
  });
});

const logout = asyncHandler(async (req, res) => {
  const { refreshToken } = req.body;
  const revokedCount = await revokeRefreshToken(
    refreshToken,
    req.user ? req.user._id : null,
  );

  res.status(200).json({
    success: true,
    message:
      revokedCount > 0
        ? 'Logged out successfully'
        : 'No active matching session was found',
  });
});

const logoutAll = asyncHandler(async (req, res) => {
  const revokedCount = await revokeAllSessionsForUser(req.user._id);
  res.status(200).json({
    success: true,
    message: `Revoked ${revokedCount} active session(s)`,
  });
});

const me = asyncHandler(async (req, res) => {
  res.status(200).json({
    success: true,
    data: sanitizeUser(req.user),
  });
});

module.exports = {
  googleLogin,
  login,
  logout,
  logoutAll,
  me,
  refresh,
  register,
};
