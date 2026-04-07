const { Server } = require('socket.io');

const User = require('./models/User');
const { extractBearerToken } = require('./middlewares/authMiddleware');
const {
  clearChatHistory,
  listChatHistory,
  sendChatMessage,
} = require('./services/chat.service');
const {
  completeAllRemindersForUser,
  createReminder,
  deleteAllRemindersForUser,
  deleteReminderForUser,
  listUserReminders,
  updateReminderForUser,
} = require('./services/reminder.service');
const { verifyAccessToken } = require('./services/auth.service');

let io;

const emitPendingReminders = async (socket, userId) => {
  const reminders = await listUserReminders(userId, { isCompleted: false });
  socket.emit('reminder:pending_loaded', reminders);
  return reminders;
};

const emitChatHistory = async (socket, userId) => {
  const history = await listChatHistory(userId, 50);
  socket.emit('chat:history_loaded', history);
  return history;
};

const initSocket = (server) => {
  io = new Server(server, {
    cors: {
      origin: '*',
      methods: ['GET', 'POST'],
    },
  });

  io.use(async (socket, next) => {
    try {
      const rawToken = socket.handshake.auth.token || '';
      const token = rawToken.startsWith('Bearer ')
        ? extractBearerToken(rawToken)
        : rawToken;

      if (!token) {
        return next(new Error('Authentication error: Token missing'));
      }

      const decoded = verifyAccessToken(token);
      const user = await User.findById(decoded.userId).select('-password');

      if (!user) {
        return next(new Error('Authentication error: User missing'));
      }

      socket.user = user;
      socket.auth = decoded;
      return next();
    } catch (error) {
      return next(new Error('Authentication error: Invalid token'));
    }
  });

  io.on('connection', (socket) => {
    const currentUserId = socket.user._id.toString();
    socket.join(currentUserId);

    console.log(`[Socket] User connected: ${socket.user.username}`);

    socket.on('chat:fetch_history', async () => {
      try {
        await emitChatHistory(socket, currentUserId);
      } catch (error) {
        console.error('Error fetching history:', error);
      }
    });

    socket.on('reminder:fetch_pending', async () => {
      try {
        await emitPendingReminders(socket, currentUserId);
      } catch (error) {
        console.error('Error fetching reminders:', error);
      }
    });

    socket.on('reminder:create', async (data) => {
      try {
        await createReminder({
          userId: currentUserId,
          payload: data,
        });
        await emitPendingReminders(socket, currentUserId);
      } catch (error) {
        console.error('Error creating manual reminder:', error);
      }
    });

    socket.on('reminder:update', async (data) => {
      try {
        await updateReminderForUser(currentUserId, data.id, data);
        await emitPendingReminders(socket, currentUserId);
      } catch (error) {
        console.error('Error updating reminder:', error);
      }
    });

    socket.on('reminder:delete', async (data) => {
      try {
        await deleteReminderForUser(currentUserId, data.id);
        await emitPendingReminders(socket, currentUserId);
      } catch (error) {
        console.error('Error deleting reminder:', error);
      }
    });

    socket.on('reminder:delete_all', async () => {
      try {
        await deleteAllRemindersForUser(currentUserId);
        socket.emit('reminder:pending_loaded', []);
      } catch (error) {
        console.error('Error deleting all reminders:', error);
      }
    });

    socket.on('reminder:complete_all', async () => {
      try {
        await completeAllRemindersForUser(currentUserId);
        await emitPendingReminders(socket, currentUserId);
      } catch (error) {
        console.error('Error completing all reminders:', error);
      }
    });

    socket.on('chat:clear_history', async () => {
      try {
        await clearChatHistory(currentUserId);
        socket.emit('chat:history_loaded', []);
      } catch (error) {
        console.error('Error clearing chat history:', error);
      }
    });

    socket.on('chat:send', async (data) => {
      try {
        socket.emit('chat:typing', { status: true });

        const lang = data?.lang || 'en';
        const result = await sendChatMessage({
          user: socket.user,
          message: data.message,
          lang,
          source: 'socket',
        });

        if (result.alertMessage) {
          socket.emit('system:alert', {
            message: result.alertMessage,
          });
        }

        if (result.reminder) {
          await emitPendingReminders(socket, currentUserId);
        }

        socket.emit('chat:receive', {
          sender: 'Shizuki',
          message: result.text,
          timestamp: result.aiMessage.timestamp,
        });
      } catch (error) {
        console.error('Error processing message:', error);
        const fallbackMessage =
          data?.lang === 'vi'
            ? 'He thong chat dang loi. Kiem tra log backend roi thu lai giup em nhe.'
            : 'The chat system hit an error. Check the backend logs and try again.';

        socket.emit('system:alert', {
          message: fallbackMessage,
        });
        socket.emit('chat:receive', {
          sender: 'Shizuki',
          message: `[ SYSTEM ] ${fallbackMessage}`,
          timestamp: new Date().toISOString(),
        });
      } finally {
        socket.emit('chat:typing', { status: false });
      }
    });

    socket.on('disconnect', () => {
      console.log(`[Socket] User disconnected: ${socket.user.username}`);
    });
  });

  return io;
};

const getIo = () => {
  if (!io) {
    throw new Error('Socket.io not initialized!');
  }
  return io;
};

module.exports = { initSocket, getIo };
