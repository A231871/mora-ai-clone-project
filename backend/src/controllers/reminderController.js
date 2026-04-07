const asyncHandler = require('../utils/asyncHandler');
const {
  completeAllRemindersForUser,
  createReminder,
  deleteAllRemindersForUser,
  deleteReminderForUser,
  listUserReminders,
  updateReminderForUser,
} = require('../services/reminder.service');

const listReminders = asyncHandler(async (req, res) => {
  const filters = { ...req.query };
  if (filters.isCompleted !== undefined) {
    filters.isCompleted = filters.isCompleted === 'true';
  }

  const reminders = await listUserReminders(req.user._id, filters);
  res.status(200).json({ success: true, data: reminders });
});

const createReminderEntry = asyncHandler(async (req, res) => {
  const reminder = await createReminder({
    userId: req.user._id,
    payload: req.body,
  });

  res.status(201).json({ success: true, data: reminder });
});

const completeAllReminders = asyncHandler(async (req, res) => {
  await completeAllRemindersForUser(req.user._id);
  res.status(200).json({
    success: true,
    message: 'All reminders marked as completed',
  });
});

const patchReminder = asyncHandler(async (req, res) => {
  const reminder = await updateReminderForUser(
    req.user._id,
    req.params.id,
    req.body,
  );

  res.status(200).json({ success: true, data: reminder });
});

const deleteReminderEntry = asyncHandler(async (req, res) => {
  if (req.params.id === 'all') {
    await deleteAllRemindersForUser(req.user._id);
    return res.status(200).json({
      success: true,
      message: 'All reminders removed',
    });
  }

  await deleteReminderForUser(req.user._id, req.params.id);
  return res.status(200).json({
    success: true,
    message: 'Reminder removed',
  });
});

const deleteAllReminders = asyncHandler(async (req, res) => {
  await deleteAllRemindersForUser(req.user._id);
  res.status(200).json({
    success: true,
    message: 'All reminders removed',
  });
});

module.exports = {
  completeAllReminders,
  createReminderEntry,
  deleteAllReminders,
  deleteReminderEntry,
  listReminders,
  patchReminder,
};
