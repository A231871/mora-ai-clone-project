const ChatMessage = require('../models/ChatMessage');
const ApiError = require('../utils/apiError');
const {
  generateResponseWithHistory,
  parseReminderIntent,
} = require('./ai.service');
const { createReminder } = require('./reminder.service');

const listChatHistory = async (userId, limit = 50) =>
  ChatMessage.find({ userId }).sort({ timestamp: 1 }).limit(limit).lean();

const clearChatHistory = async (userId) => {
  await ChatMessage.deleteMany({ userId });
};

const sendChatMessage = async ({
  user,
  message,
  lang = 'en',
  source = 'http',
}) => {
  if (!message || !message.trim()) {
    throw new ApiError(400, 'message is required');
  }

  // Every chat turn is persisted so the AI can respond with recent context.
  await ChatMessage.create({
    userId: user._id,
    role: 'user',
    content: message.trim(),
    lang,
    source,
  });

  const intentData = await parseReminderIntent(message.trim(), lang);

  let finalAiReply = '';
  let systemAlertMessage = null;
  let createdReminder = null;

  if (intentData.systemError) {
    // AI/runtime failures are converted into user-safe system replies instead of crashing chat.
    finalAiReply = intentData.systemError.userMessage;
    systemAlertMessage = intentData.systemError.alertMessage;
  } else if (intentData.isReminder && intentData.time) {
    // The chat assistant can create real backend reminders, so chat is not
    // just conversational text generation.
    createdReminder = await createReminder({
      userId: user._id,
      payload: {
        task: intentData.task,
        scheduledTime: intentData.time,
        daysOfWeek: [],
      },
    });

    const displayTime = new Date(intentData.time).toLocaleString(
      lang === 'vi' ? 'vi-VN' : 'en-US',
      { timeZone: 'Asia/Ho_Chi_Minh' },
    );

    if (lang === 'vi') {
      finalAiReply = `[ HỆ THỐNG ] Đã xác nhận chỉ thị! Em sẽ nhắc anh: ${intentData.task} vào lúc ${displayTime}.`;
    } else {
      finalAiReply = `[ SYSTEM ] Acknowledged! I will remind you: ${intentData.task} at ${displayTime}.`;
    }
  } else {
    // Normal conversation path: send recent message history into Gemini.
    let recentHistory = await ChatMessage.find({ userId: user._id })
      .sort({ timestamp: -1 })
      .limit(10)
      .lean();

    recentHistory = recentHistory.reverse();

    const aiResult = await generateResponseWithHistory(
      message.trim(),
      recentHistory,
      lang,
    );
    finalAiReply = aiResult.text;
    systemAlertMessage = aiResult.alertMessage;
  }

  const savedAiMessage = await ChatMessage.create({
    userId: user._id,
    role: 'model',
    content: finalAiReply,
    lang,
    source,
  });

  return {
    aiMessage: savedAiMessage,
    alertMessage: systemAlertMessage,
    reminder: createdReminder,
    text: finalAiReply,
  };
};

module.exports = {
  clearChatHistory,
  listChatHistory,
  sendChatMessage,
};
