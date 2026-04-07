const cron = require('node-cron');
const { getIo } = require('../socketRuntime');
const { processDueReminders } = require('./reminder.service');

const initCronJobs = () => {
  // Minute-level polling is enough for class-project reminders and keeps
  // the scheduling logic straightforward.
  cron.schedule('* * * * *', async () => {
    try {
      const io = getIo();
      const processedCount = await processDueReminders(io);

      if (processedCount > 0) {
        console.log(`[Cron] Executed ${processedCount} pending reminder(s).`);
      }
    } catch (err) {
      console.error('[Cron Error] Failed processing reminders:', err);
    }
  });
  console.log('[Cron] Reminder schedule initialized. Running every 1 minute.');
};

module.exports = { initCronJobs };
