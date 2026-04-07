const Reminder = require('../models/Reminder');
const ApiError = require('../utils/apiError');

const normalizeReminderInput = (payload = {}) => {
  const scheduledTime = payload.scheduledTime
    ? new Date(payload.scheduledTime)
    : null;

  if (!payload.task && !payload.message) {
    throw new ApiError(400, 'Please provide task or message');
  }

  if (!scheduledTime || Number.isNaN(scheduledTime.getTime())) {
    throw new ApiError(400, 'Please provide a valid scheduledTime');
  }

  return {
    message: payload.task || payload.message,
    scheduledTime,
    daysOfWeek: Array.isArray(payload.daysOfWeek) ? payload.daysOfWeek : [],
    projectId: payload.projectId || null,
    taskId: payload.taskId || null,
    isCompleted: payload.isCompleted === true,
  };
};

const listUserReminders = async (userId, filters = {}) => {
  const query = { userId };

  if (filters.projectId) {
    query.projectId = filters.projectId;
  }

  if (filters.taskId) {
    query.taskId = filters.taskId;
  }

  if (filters.isCompleted !== undefined) {
    query.isCompleted = filters.isCompleted;
  }

  return Reminder.find(query).sort({ scheduledTime: 1 }).lean();
};

const createReminder = async ({ userId, payload, session = null }) => {
  const normalized = normalizeReminderInput(payload);
  const reminder = await Reminder.create(
    [
      {
        userId,
        ...normalized,
      },
    ],
    session ? { session } : undefined,
  );

  return reminder[0];
};

const getReminderForUser = async (userId, reminderId) => {
  const reminder = await Reminder.findById(reminderId);
  if (!reminder) {
    throw new ApiError(404, 'Reminder not found');
  }

  if (reminder.userId.toString() !== userId.toString()) {
    throw new ApiError(403, 'User not authorized for this reminder');
  }

  return reminder;
};

const updateReminderForUser = async (userId, reminderId, payload) => {
  const reminder = await getReminderForUser(userId, reminderId);
  const touchedScheduleFields =
    payload.task !== undefined ||
    payload.message !== undefined ||
    payload.scheduledTime !== undefined ||
    payload.daysOfWeek !== undefined ||
    payload.projectId !== undefined ||
    payload.taskId !== undefined;

  if (payload.task !== undefined || payload.message !== undefined) {
    reminder.message = payload.task || payload.message;
  }

  if (payload.scheduledTime !== undefined) {
    const scheduledTime = new Date(payload.scheduledTime);
    if (Number.isNaN(scheduledTime.getTime())) {
      throw new ApiError(400, 'scheduledTime is invalid');
    }
    reminder.scheduledTime = scheduledTime;
  }

  if (payload.daysOfWeek !== undefined) {
    reminder.daysOfWeek = Array.isArray(payload.daysOfWeek)
      ? payload.daysOfWeek
      : [];
  }

  if (payload.isCompleted !== undefined) {
    reminder.isCompleted = payload.isCompleted;
  } else if (touchedScheduleFields) {
    reminder.isCompleted = false;
  }

  if (payload.projectId !== undefined) {
    reminder.projectId = payload.projectId || null;
  }

  if (payload.taskId !== undefined) {
    reminder.taskId = payload.taskId || null;
  }

  await reminder.save();
  return reminder;
};

const deleteReminderForUser = async (userId, reminderId) => {
  const reminder = await getReminderForUser(userId, reminderId);
  await reminder.deleteOne();
};

const deleteAllRemindersForUser = async (userId) => {
  await Reminder.deleteMany({ userId });
};

const completeAllRemindersForUser = async (userId) => {
  await Reminder.updateMany(
    { userId, isCompleted: false },
    { $set: { isCompleted: true } },
  );
};

const processDueReminders = async (io) => {
  const pendingReminders = await Reminder.find({
    scheduledTime: { $lte: new Date() },
    isCompleted: false,
    daysOfWeek: { $size: 0 },
  });

  if (pendingReminders.length === 0) {
    return 0;
  }

  for (const reminder of pendingReminders) {
    io.to(reminder.userId.toString()).emit('system:alert', {
      message: reminder.message,
    });

    reminder.isCompleted = true;
    await reminder.save();
  }

  return pendingReminders.length;
};

module.exports = {
  completeAllRemindersForUser,
  createReminder,
  deleteAllRemindersForUser,
  deleteReminderForUser,
  getReminderForUser,
  listUserReminders,
  processDueReminders,
  updateReminderForUser,
};
