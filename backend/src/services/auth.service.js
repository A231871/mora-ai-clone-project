const crypto = require('crypto');
const jwt = require('jsonwebtoken');

const AuthSession = require('../models/AuthSession');
const User = require('../models/User');
const ApiError = require('../utils/apiError');

const ACCESS_TOKEN_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '7d';
const REFRESH_TOKEN_EXPIRES_DAYS = Number(
  process.env.REFRESH_TOKEN_EXPIRES_DAYS || 30,
);

// Refresh tokens are never stored in plaintext. If the database leaks,
// attackers still do not get usable refresh credentials.
const hashRefreshToken = (refreshToken) =>
  crypto.createHash('sha256').update(refreshToken).digest('hex');

const buildRefreshExpiry = () =>
  new Date(Date.now() + REFRESH_TOKEN_EXPIRES_DAYS * 24 * 60 * 60 * 1000);

const generateRefreshToken = () => crypto.randomBytes(48).toString('hex');

const deriveAuthProvider = (user) => {
  if (user.googleId) {
    return 'google';
  }

  if (user.password) {
    return 'local';
  }

  return 'unknown';
};

const sanitizeUser = (user) => ({
  // Controllers always return this safe projection instead of the raw Mongoose document.
  id: user._id,
  username: user.username,
  email: user.email || null,
  googleId: user.googleId || null,
  authProvider: deriveAuthProvider(user),
  systemRole: user.systemRole,
  profile: user.profile || { displayName: '', bio: '' },
  avatarConfig: user.avatarConfig,
  avatarAssetId: user.avatarAssetId || null,
  lastLoginAt: user.lastLoginAt || null,
  createdAt: user.createdAt,
  updatedAt: user.updatedAt,
});

const signAccessToken = (user) =>
  jwt.sign(
    {
      userId: user._id.toString(),
      username: user.username,
      systemRole: user.systemRole,
    },
    process.env.JWT_SECRET,
    { expiresIn: ACCESS_TOKEN_EXPIRES_IN },
  );

const verifyAccessToken = (token) =>
  jwt.verify(token, process.env.JWT_SECRET);

const issueAuthTokens = async (user, meta = {}) => {
  // Access tokens stay short and self-contained.
  // Refresh tokens are database-backed so we can revoke sessions individually.
  const token = signAccessToken(user);
  const refreshToken = generateRefreshToken();

  await AuthSession.create({
    userId: user._id,
    refreshTokenHash: hashRefreshToken(refreshToken),
    userAgent: meta.userAgent || '',
    ipAddress: meta.ipAddress || '',
    expiresAt: buildRefreshExpiry(),
    lastUsedAt: new Date(),
  });

  return {
    token,
    refreshToken,
  };
};

const buildAuthPayload = async (user, meta = {}) => {
  const tokens = await issueAuthTokens(user, meta);
  return {
    message: 'Login successful!',
    token: tokens.token,
    refreshToken: tokens.refreshToken,
    avatarConfig: user.avatarConfig,
    user: sanitizeUser(user),
  };
};

const getSessionByRefreshToken = async (refreshToken) => {
  if (!refreshToken) {
    throw new ApiError(400, 'refreshToken is required');
  }

  const authSession = await AuthSession.findOne({
    refreshTokenHash: hashRefreshToken(refreshToken),
    isRevoked: false,
    expiresAt: { $gt: new Date() },
  });

  if (!authSession) {
    throw new ApiError(401, 'Refresh token is invalid or expired');
  }

  return authSession;
};

const rotateRefreshToken = async (refreshToken, meta = {}) => {
  // Rotation makes refresh tokens single-use. Reusing an old token fails because
  // the old AuthSession is marked revoked before a new pair is issued.
  const authSession = await getSessionByRefreshToken(refreshToken);
  const user = await User.findById(authSession.userId);

  if (!user) {
    throw new ApiError(401, 'User for refresh token no longer exists');
  }

  authSession.isRevoked = true;
  authSession.revokedAt = new Date();
  authSession.lastUsedAt = new Date();
  await authSession.save();

  return {
    user,
    ...(await buildAuthPayload(user, meta)),
  };
};

const revokeRefreshToken = async (refreshToken, userId = null) => {
  if (!refreshToken) {
    return 0;
  }

  const query = {
    refreshTokenHash: hashRefreshToken(refreshToken),
    isRevoked: false,
  };

  if (userId) {
    query.userId = userId;
  }

  const result = await AuthSession.updateMany(query, {
    $set: {
      isRevoked: true,
      revokedAt: new Date(),
      lastUsedAt: new Date(),
    },
  });

  return result.modifiedCount || 0;
};

const revokeAllSessionsForUser = async (userId) => {
  const result = await AuthSession.updateMany(
    { userId, isRevoked: false },
    {
      $set: {
        isRevoked: true,
        revokedAt: new Date(),
        lastUsedAt: new Date(),
      },
    },
  );

  return result.modifiedCount || 0;
};

const ensureAdminUser = async () => {
  // This is a safety net for class/demo environments: the first account becomes
  // admin if no admin currently exists, so the system never gets stuck without
  // an administrative operator.
  const totalUsers = await User.countDocuments();
  if (totalUsers === 0) {
    return;
  }

  await User.updateMany(
    { systemRole: { $exists: false } },
    { $set: { systemRole: 'member' } },
  );

  const adminCount = await User.countDocuments({ systemRole: 'admin' });
  if (adminCount > 0) {
    return;
  }

  const earliestUser = await User.findOne().sort({ createdAt: 1 });
  if (!earliestUser) {
    return;
  }

  await User.updateMany(
    { _id: { $ne: earliestUser._id } },
    { $set: { systemRole: 'member' } },
  );

  earliestUser.systemRole = 'admin';
  await earliestUser.save();
};

module.exports = {
  buildAuthPayload,
  deriveAuthProvider,
  ensureAdminUser,
  getSessionByRefreshToken,
  issueAuthTokens,
  revokeAllSessionsForUser,
  revokeRefreshToken,
  rotateRefreshToken,
  sanitizeUser,
  signAccessToken,
  verifyAccessToken,
};
