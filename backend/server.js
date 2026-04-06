require('dotenv').config();

const express = require('express');
const http = require('http');
const cors = require('cors');

const connectDB = require('./src/config/db');
const authRoutes = require('./src/routes/authRoutes');
const reminderRoutes = require('./src/routes/reminderRoutes');
const { initSocket } = require('./src/socket');
const { getAiRuntimeSummary } = require('./src/services/ai.service');
const { initCronJobs } = require('./src/services/cron.service');

const app = express();
const server = http.createServer(app);
const PORT = process.env.PORT || 5000;

app.use(cors());
app.use(express.json());

connectDB();

app.use('/api/auth', authRoutes);
app.use('/api/reminders', reminderRoutes);

app.get('/', (_req, res) => {
  res.send('Mora-Like AI Backend is running.');
});

initSocket(server);
initCronJobs();

server.listen(PORT, () => {
  const aiSummary = getAiRuntimeSummary();
  console.log(`Server running on http://localhost:${PORT}`);
  console.log(
    `[Gemini] keyLoaded=${aiSummary.keyLoaded} keySuffix=${aiSummary.keySuffix || 'n/a'} models=${aiSummary.models.join(', ')}`,
  );
});
