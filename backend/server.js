require('dotenv').config();

const express = require('express');
const http = require('http');
const path = require('path');
const cors = require('cors');

const connectDB = require('./src/config/db');
const authRoutes = require('./src/routes/authRoutes');
const userRoutes = require('./src/routes/userRoutes');
const adminRoutes = require('./src/routes/adminRoutes');
const projectRoutes = require('./src/routes/projectRoutes');
const taskRoutes = require('./src/routes/taskRoutes');
const chatRoutes = require('./src/routes/chatRoutes');
const fileRoutes = require('./src/routes/fileRoutes');
const reminderRoutes = require('./src/routes/reminderRoutes');
const { errorHandler, notFound } = require('./src/middlewares/errorMiddleware');
const { initSocket } = require('./src/socketRuntime');
const { getAiRuntimeSummary } = require('./src/services/ai.service');
const { ensureAdminUser } = require('./src/services/auth.service');
const { initCronJobs } = require('./src/services/cron.service');

const app = express();
const server = http.createServer(app);
const PORT = process.env.PORT || 5000;

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/projects', projectRoutes);
app.use('/api/tasks', taskRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/files', fileRoutes);
app.use('/api/reminders', reminderRoutes);

app.get('/', (_req, res) => {
  res.send('Shizuki AI productivity backend is running.');
});

app.use(notFound);
app.use(errorHandler);

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
