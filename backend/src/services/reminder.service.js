const Reminder = require('../models/Reminder');
const ApiError = require('../utils/apiError');

const WEEKDAY_NAMES = [
  'sunday',
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
];

const normalizeDaysOfWeek = (daysOfWeek = []) => [
  // We accept short forms such as "mon" from clients but store full normalized
  // weekday names in the database.
  ...new Set(
    (Array.isArray(daysOfWeek) ? daysOfWeek : [])
      .map((day) => day?.toString().trim().toLowerCase())
      .map((day) => {
        if (day === 'mon') return 'monday';
        if (day === 'tue' || day === 'tues') return 'tuesday';
        if (day === 'wed') return 'wednesday';
        if (day === 'thu' || day === 'thur' || day === 'thurs') return 'thursday';
        if (day === 'fri') return 'friday';
        if (day === 'sat') return 'saturday';
        if (day === 'sun') return 'sunday';
        return day;
      })
      .filter((day) => WEEKDAY_NAMES.includes(day)),
  ),
];

const getNextRecurringScheduledTime = (
  scheduledTime,
  daysOfWeek = [],
  now = new Date(),
) => {
  // Recurring reminders keep the original time-of-day and search ahead
  // for the next allowed weekday.
  const normalizedDays = normalizeDaysOfWeek(daysOfWeek);
  if (normalizedDays.length === 0) {
    return null;
  }

  const baseTime = new Date(scheduledTime);
  if (Number.isNaN(baseTime.getTime())) {
    throw new ApiError(400, 'scheduledTime is invalid');
  }

  for (let offset = 1; offset <= 14; offset += 1) {
    const candidate = new Date(baseTime);
    candidate.setDate(candidate.getDate() + offset);

    if (!normalizedDays.includes(WEEKDAY_NAMES[candidate.getDay()])) {
      continue;
    }

    if (candidate > now) {
      return candidate;
    }
  }

  return null;
};

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
    daysOfWeek: normalizeDaysOfWeek(payload.daysOfWeek),
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
    reminder.daysOfWeek = normalizeDaysOfWeek(payload.daysOfWeek);
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
  const now = new Date();
  const pendingReminders = await Reminder.find({
    scheduledTime: { $lte: now },
    isCompleted: false,
  });

  if (pendingReminders.length === 0) {
    return 0;
  }

  let processedCount = 0;

  for (const reminder of pendingReminders) {
    // Real-time delivery happens through Socket.IO, not polling from the client.
    io.to(reminder.userId.toString()).emit('system:alert', {
      message: reminder.message,
    });

    // One-time reminders complete after firing.
    // Recurring reminders advance to the next eligible day instead.
    const nextScheduledTime = getNextRecurringScheduledTime(
      reminder.scheduledTime,
      reminder.daysOfWeek,
      now,
    );

    if (nextScheduledTime) {
      reminder.daysOfWeek = normalizeDaysOfWeek(reminder.daysOfWeek);
      reminder.scheduledTime = nextScheduledTime;
      reminder.isCompleted = false;
    } else {
      reminder.isCompleted = true;
    }

    await reminder.save();
    processedCount += 1;
  }

  return processedCount;
};

module.exports = {
  completeAllRemindersForUser,
  createReminder,
  deleteAllRemindersForUser,
  deleteReminderForUser,
  getNextRecurringScheduledTime,
  getReminderForUser,
  listUserReminders,
  normalizeDaysOfWeek,
  processDueReminders,
  updateReminderForUser,
};
