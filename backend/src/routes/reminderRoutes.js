const express = require('express');
const router = express.Router();
const {
  completeAllReminders,
  createReminderEntry,
  deleteAllReminders,
  deleteReminderEntry,
  listReminders,
  patchReminder,
} = require('../controllers/reminderController');
const { protect } = require('../middlewares/authMiddleware');

router.get('/', protect, listReminders);
router.post('/', protect, createReminderEntry);
router.put('/complete-all', protect, completeAllReminders);
router.delete('/all', protect, deleteAllReminders);
router.put('/:id', protect, patchReminder);
router.patch('/:id', protect, patchReminder);
router.delete('/:id', protect, deleteReminderEntry);

module.exports = router;
