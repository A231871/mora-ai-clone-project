const User = require('../models/User');
const ApiError = require('../utils/apiError');
const { verifyAccessToken } = require('../services/auth.service');

const extractBearerToken = (authorizationHeader = '') => {
  if (!authorizationHeader.startsWith('Bearer ')) {
    return null;
  }

  return authorizationHeader.split(' ')[1];
};

const protect = async (req, _res, next) => {
  try {
    const token = extractBearerToken(req.headers.authorization || '');
    if (!token) {
      throw new ApiError(401, 'Not authorized, no token');
    }

    const decoded = verifyAccessToken(token);
    const user = await User.findById(decoded.userId).select('-password');

    if (!user) {
      throw new ApiError(401, 'Not authorized, user does not exist');
    }

    req.user = user;
    req.auth = decoded;
    next();
  } catch (error) {
    next(
      error instanceof ApiError
        ? error
        : new ApiError(401, 'Not authorized, token failed'),
    );
  }
};

const authorizeSystemRoles = (...roles) => (req, _res, next) => {
  if (!req.user) {
    return next(new ApiError(401, 'Authentication required'));
  }

  if (!roles.includes(req.user.systemRole)) {
    return next(new ApiError(403, 'You do not have permission for this action'));
  }

  return next();
};

module.exports = {
  authorizeSystemRoles,
  extractBearerToken,
  protect,
};
