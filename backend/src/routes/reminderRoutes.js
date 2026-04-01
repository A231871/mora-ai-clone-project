const express = require('express');
const router = express.Router();
const Reminder = require('../models/Reminder');
const { protect } = require('../middlewares/authMiddleware');

// @route   GET /api/reminders
// @desc    Get all pending reminders for logged in user
// @access  Private
router.get('/', protect, async (req, res) => {
  try {
    const currentUserId = req.user._id || req.user.id || req.user.userId;
    const reminders = await Reminder.find({ userId: currentUserId }).sort({ scheduledTime: 1 });
    res.status(200).json({ success: true, data: reminders });
  } catch (error) {
    console.error('Error fetching reminders:', error);
    res.status(500).json({ success: false, message: 'Server error fetching reminders' });
  }
});

// @route   POST /api/reminders
// @desc    Create a new reminder
// @access  Private
router.post('/', protect, async (req, res) => {
  try {
    const { task, scheduledTime, daysOfWeek } = req.body;
    const currentUserId = req.user._id || req.user.id || req.user.userId;

    if (!task || !scheduledTime) {
      return res.status(400).json({ success: false, message: 'Please provide task and scheduledTime' });
    }

    const newReminder = await Reminder.create({
      userId: currentUserId,
      message: task,
      scheduledTime: new Date(scheduledTime),
      isCompleted: false,
      daysOfWeek: daysOfWeek || []
    });

    res.status(201).json({ success: true, data: newReminder });
  } catch (error) {
    console.error('Error creating reminder:', error);
    res.status(500).json({ success: false, message: 'Server error creating reminder' });
  }
});

// @route   PUT /api/reminders/complete-all
// @desc    Complete all pending reminders
// @access  Private
router.put('/complete-all', protect, async (req, res) => {
  try {
    const currentUserId = req.user._id || req.user.id || req.user.userId;
    
    await Reminder.updateMany(
      { userId: currentUserId, isCompleted: false },
      { $set: { isCompleted: true } }
    );
    
    res.status(200).json({ success: true, message: 'All reminders marked as completed' });
  } catch (error) {
    console.error('Error completing all reminders:', error);
    res.status(500).json({ success: false, message: 'Server error completing all reminders' });
  }
});

// @route   PUT /api/reminders/:id
// @desc    Update a reminder
// @access  Private
router.put('/:id', protect, async (req, res) => {
  try {
    const { isCompleted, task, scheduledTime, daysOfWeek } = req.body;
    const currentUserId = req.user._id || req.user.id || req.user.userId;

    let reminder = await Reminder.findById(req.params.id);

    if (!reminder) {
      return res.status(404).json({ success: false, message: 'Reminder not found' });
    }

    if (reminder.userId.toString() !== currentUserId.toString()) {
        return res.status(401).json({ success: false, message: 'User not authorized' });
    }

    let updateFields = {};
    if (isCompleted !== undefined) updateFields.isCompleted = isCompleted;
    if (task) updateFields.message = task;
    if (scheduledTime) updateFields.scheduledTime = new Date(scheduledTime);
    if (daysOfWeek !== undefined) updateFields.daysOfWeek = daysOfWeek;

    reminder = await Reminder.findByIdAndUpdate(
      req.params.id,
      updateFields,
      { new: true }
    );

    res.status(200).json({ success: true, data: reminder });
  } catch (error) {
    console.error('Error updating reminder:', error);
    res.status(500).json({ success: false, message: 'Server error updating reminder' });
  }
});

// @route   DELETE /api/reminders/:id
// @desc    Delete a reminder
// @access  Private
router.delete('/:id', protect, async (req, res) => {
  try {
    if (req.params.id === 'all') {
      const currentUserId = req.user._id || req.user.id || req.user.userId;
      await Reminder.deleteMany({ userId: currentUserId });
      return res.status(200).json({ success: true, message: 'All reminders removed' });
    }

    const currentUserId = req.user._id || req.user.id || req.user.userId;

    const reminder = await Reminder.findById(req.params.id);

    if (!reminder) {
      return res.status(404).json({ success: false, message: 'Reminder not found' });
    }

    if (reminder.userId.toString() !== currentUserId.toString()) {
      return res.status(401).json({ success: false, message: 'User not authorized' });
    }

    await Reminder.findByIdAndDelete(req.params.id);

    res.status(200).json({ success: true, message: 'Reminder removed' });
  } catch (error) {
    console.error('Error deleting reminder:', error);
    res.status(500).json({ success: false, message: 'Server error deleting reminder' });
  }
});

module.exports = router;
