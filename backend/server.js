require('dotenv').config();

const http = require('http');

const connectDB = require('./src/config/db');
const app = require('./src/app');
const { initSocket } = require('./src/socketRuntime');
const { getAiRuntimeSummary } = require('./src/services/ai.service');
const { ensureAdminUser } = require('./src/services/auth.service');
const { initCronJobs } = require('./src/services/cron.service');

const server = http.createServer(app);
const PORT = process.env.PORT || 5000;

const startServer = async () => {
  await connectDB();
  await ensureAdminUser();

  initSocket(server);

  server.once('error', (error) => {
    if (error.code === 'EADDRINUSE') {
      console.error(
        `Port ${PORT} is already in use. Stop the process using this port or change PORT in backend/.env.`,
      );
    } else {
      console.error('HTTP server failed to start:', error);
    }

    process.exit(1);
  });

  server.listen(PORT, () => {
    initCronJobs();
    const aiSummary = getAiRuntimeSummary();
    console.log(`Server running on http://localhost:${PORT}`);
    console.log(
      `[Gemini] keyLoaded=${aiSummary.keyLoaded} keySuffix=${
        aiSummary.keySuffix || 'n/a'
      } models=${aiSummary.models.join(', ')}`,
    );
  });
};

startServer().catch((error) => {
  console.error('Failed to start server:', error);
  process.exit(1);
});
