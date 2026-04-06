const { Server } = require('socket.io');
const jwt = require('jsonwebtoken');

const {
  generateResponseWithHistory,
  parseReminderIntent,
} = require('./services/ai.service');
const ChatMessage = require('./models/ChatMessage');
const Reminder = require('./models/Reminder');

let io;

const initSocket = (server) => {
  io = new Server(server, {
    cors: {
      origin: '*',
      methods: ['GET', 'POST'],
    },
  });

  io.use((socket, next) => {
    const token = socket.handshake.auth.token;
    if (!token) {
      return next(new Error('Authentication error: Token missing'));
    }

    jwt.verify(token, process.env.JWT_SECRET, (err, decoded) => {
      if (err) {
        return next(new Error('Authentication error: Invalid token'));
      }

      socket.user = decoded;
      console.log('Decoded Token Data:', socket.user);
      next();
    });
  });

  io.on('connection', (socket) => {
    const currentUserId =
      socket.user._id || socket.user.id || socket.user.userId;
    if (!currentUserId) {
      console.error(
        '[Socket Error] JWT token does not contain a valid user ID:',
        socket.user,
      );
      return;
    }

    console.log(`[Socket] User connected: ${socket.user.username}`);
    socket.join(currentUserId.toString());

    socket.on('chat:fetch_history', async () => {
      try {
        const history = await ChatMessage.find({ userId: currentUserId })
          .sort({ timestamp: 1 })
          .limit(50);
        socket.emit('chat:history_loaded', history);
      } catch (err) {
        console.error('Error fetching history:', err);
      }
    });

    socket.on('reminder:fetch_pending', async () => {
      try {
        const pendingReminders = await Reminder.find({
          userId: currentUserId,
        }).sort({ scheduledTime: 1 });

        socket.emit('reminder:pending_loaded', pendingReminders);
      } catch (err) {
        console.error('Error fetching pending reminders:', err);
      }
    });

    socket.on('reminder:create', async (data) => {
      try {
        await Reminder.create({
          userId: currentUserId,
          message: data.task,
          scheduledTime: new Date(data.scheduledTime),
          isCompleted: false,
          daysOfWeek: data.daysOfWeek || [],
        });

        const pendingReminders = await Reminder.find({
          userId: currentUserId,
        }).sort({ scheduledTime: 1 });

        socket.emit('reminder:pending_loaded', pendingReminders);
      } catch (err) {
        console.error('Error creating manual reminder:', err);
      }
    });

    socket.on('reminder:update', async (data) => {
      try {
        const updateFields = {};
        if (data.isCompleted !== undefined) {
          updateFields.isCompleted = data.isCompleted;
        }
        if (data.task) {
          updateFields.message = data.task;
        }
        if (data.scheduledTime) {
          updateFields.scheduledTime = new Date(data.scheduledTime);
        }
        if (data.daysOfWeek !== undefined) {
          updateFields.daysOfWeek = data.daysOfWeek;
        }

        await Reminder.findByIdAndUpdate(data.id, updateFields);
        const pendingReminders = await Reminder.find({
          userId: currentUserId,
        }).sort({ scheduledTime: 1 });
        socket.emit('reminder:pending_loaded', pendingReminders);
      } catch (err) {
        console.error('Error updating reminder:', err);
      }
    });

    socket.on('reminder:delete', async (data) => {
      try {
        await Reminder.findByIdAndDelete(data.id);
        const pendingReminders = await Reminder.find({
          userId: currentUserId,
        }).sort({ scheduledTime: 1 });
        socket.emit('reminder:pending_loaded', pendingReminders);
      } catch (err) {
        console.error('Error deleting reminder:', err);
      }
    });

    socket.on('reminder:delete_all', async () => {
      try {
        await Reminder.deleteMany({ userId: currentUserId });
        socket.emit('reminder:pending_loaded', []);
      } catch (err) {
        console.error('Error deleting all reminders:', err);
      }
    });

    socket.on('reminder:complete_all', async () => {
      try {
        await Reminder.updateMany(
          { userId: currentUserId, isCompleted: false },
          { $set: { isCompleted: true } },
        );
        const pendingReminders = await Reminder.find({
          userId: currentUserId,
        }).sort({ scheduledTime: 1 });
        socket.emit('reminder:pending_loaded', pendingReminders);
      } catch (err) {
        console.error('Error completing all reminders:', err);
      }
    });

    socket.on('chat:clear_history', async () => {
      try {
        await ChatMessage.deleteMany({ userId: currentUserId });
        socket.emit('chat:history_loaded', []);
      } catch (err) {
        console.error('Error clearing chat history:', err);
      }
    });

    socket.on('chat:send', async (data) => {
      try {
        console.log(`[Chat] Received from user: ${data.message}`);
        socket.emit('chat:typing', { status: true });

        const lang = data.lang || 'en';
        console.log('[DEBUG] Chat payload lang:', lang);

        const intentData = await parseReminderIntent(data.message, lang);

        await ChatMessage.create({
          userId: currentUserId,
          role: 'user',
          content: data.message,
        });

        let finalAiReply = '';
        let systemAlertMessage = null;

        if (intentData.systemError) {
          finalAiReply = intentData.systemError.userMessage;
          systemAlertMessage = intentData.systemError.alertMessage;
        } else if (intentData.isReminder && intentData.time) {
          await Reminder.create({
            userId: currentUserId,
            message: intentData.task,
            scheduledTime: new Date(intentData.time),
            isCompleted: false,
          });

          const displayTime = new Date(intentData.time).toLocaleString(
            lang === 'vi' ? 'vi-VN' : 'en-US',
            { timeZone: 'Asia/Ho_Chi_Minh' },
          );

          if (lang === 'vi') {
            finalAiReply = `[ HỆ THỐNG ] Đã xác nhận chỉ thị! Em sẽ nhắc anh: ${intentData.task} vào lúc ${displayTime} 🤖`;
          } else {
            finalAiReply = `[ SYSTEM ] Acknowledged! I will remind you: ${intentData.task} at ${displayTime} 🤖`;
          }
        } else {
          let recentHistory = await ChatMessage.find({
            userId: currentUserId,
          })
            .sort({ timestamp: -1 })
            .limit(10)
            .lean();

          recentHistory = recentHistory.reverse();

          const aiResult = await generateResponseWithHistory(
            data.message,
            recentHistory,
            lang,
          );
          finalAiReply = aiResult.text;
          systemAlertMessage = aiResult.alertMessage;
        }

        const savedAiMessage = await ChatMessage.create({
          userId: currentUserId,
          role: 'model',
          content: finalAiReply,
        });

        if (systemAlertMessage) {
          socket.emit('system:alert', {
            message: systemAlertMessage,
          });
        }

        socket.emit('chat:receive', {
          sender: 'Shizuki',
          message: finalAiReply,
          timestamp: savedAiMessage.timestamp,
        });

        socket.emit('chat:typing', { status: false });
      } catch (err) {
        console.error('Error processing message:', err);
        const fallbackMessage =
          data?.lang === 'vi'
            ? 'Hệ thống chat đang lỗi. Kiểm tra log backend rồi thử lại giúp em nhé.'
            : 'The chat system hit an error. Check the backend logs and try again.';

        socket.emit('system:alert', {
          message: fallbackMessage,
        });
        socket.emit('chat:receive', {
          sender: 'Shizuki',
          message: `[ SYSTEM ] ${fallbackMessage}`,
          timestamp: new Date().toISOString(),
        });
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
