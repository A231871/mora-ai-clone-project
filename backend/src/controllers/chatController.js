const asyncHandler = require('../utils/asyncHandler');
const ApiError = require('../utils/apiError');
const {
  clearChatHistory,
  listChatHistory,
  sendChatMessage,
} = require('../services/chat.service');

const getChatHistory = asyncHandler(async (req, res) => {
  const limit = req.query.limit ? Number(req.query.limit) : 50;
  const history = await listChatHistory(req.user._id, limit);
  res.status(200).json({
    success: true,
    data: history,
  });
});

const clearHistory = asyncHandler(async (req, res) => {
  await clearChatHistory(req.user._id);
  res.status(200).json({
    success: true,
    message: 'Chat history cleared successfully',
  });
});

const sendMessage = asyncHandler(async (req, res) => {
  const { message, lang } = req.body;
  if (!message) {
    throw new ApiError(400, 'message is required');
  }

  const result = await sendChatMessage({
    user: req.user,
    message,
    lang: lang || 'en',
    source: 'http',
  });

  res.status(200).json({
    success: true,
    data: {
      message: result.text,
      aiMessage: result.aiMessage,
      reminder: result.reminder,
      alertMessage: result.alertMessage,
    },
  });
});

module.exports = {
  clearHistory,
  getChatHistory,
  sendMessage,
};
