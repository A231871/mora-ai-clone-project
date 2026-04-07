const multer = require('multer');

const ApiError = require('../utils/apiError');

const notFound = (req, _res, next) => {
  next(new ApiError(404, `Route not found: ${req.method} ${req.originalUrl}`));
};

const errorHandler = (error, _req, res, _next) => {
  const statusCode = error.statusCode || 500;
  const message = error.message || 'Internal server error';

  if (error instanceof multer.MulterError) {
    return res.status(400).json({
      success: false,
      message: error.message,
    });
  }

  return res.status(statusCode).json({
    success: false,
    message,
    details: error.details || null,
    stack:
      process.env.NODE_ENV === 'production' ? undefined : error.stack,
  });
};

module.exports = {
  errorHandler,
  notFound,
};
