const cron = require('node-cron');
const Reminder = require('../models/Reminder');
const { getIo } = require('../socket');

const initCronJobs = () => {
  cron.schedule('* * * * *', async () => {
    try {
      const pendingReminders = await Reminder.find({
        scheduledTime: { $lte: new Date() },
        isCompleted: false
      });

      if (pendingReminders.length > 0) {
        console.log(`[Cron] Executing ${pendingReminders.length} pending reminders...`);
        const io = getIo();
        
        for (const reminder of pendingReminders) {
          // Push notification down the WebSocket to this exact user's room
          io.to(reminder.userId.toString()).emit('system:alert', { message: reminder.message });
          
          // Mark as processed
          reminder.isCompleted = true;
          await reminder.save();
        }
      }
    } catch (err) {
      console.error('[Cron Error] Failed processing reminders:', err);
    }
  });
  console.log('[Cron] Proactive Reminder schedule initialized. Running every 1 minute.');
};

module.exports = { initCronJobs };
