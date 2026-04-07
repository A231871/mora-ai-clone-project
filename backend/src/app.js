const express = require('express');
const path = require('path');
const cors = require('cors');

const authRoutes = require('./routes/authRoutes');
const userRoutes = require('./routes/userRoutes');
const adminRoutes = require('./routes/adminRoutes');
const projectRoutes = require('./routes/projectRoutes');
const taskRoutes = require('./routes/taskRoutes');
const chatRoutes = require('./routes/chatRoutes');
const fileRoutes = require('./routes/fileRoutes');
const reminderRoutes = require('./routes/reminderRoutes');
const { errorHandler, notFound } = require('./middlewares/errorMiddleware');

const app = express();

// Global middleware is mounted once here so every feature module shares
// the same CORS policy, JSON parsing, and upload access path.
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// The backend is organized by feature area, so each route group delegates
// the real business logic to its own controller/service pair.
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

// These handlers stay last so unmatched routes and thrown ApiError instances
// are turned into consistent JSON responses.
app.use(notFound);
app.use(errorHandler);

module.exports = app;
