const { Server } = require("socket.io");
const jwt = require("jsonwebtoken");
const { generateResponseWithHistory } = require("./services/ai.service");
const ChatMessage = require("./models/ChatMessage");

let io;

const initSocket = (server) => {
  io = new Server(server, {
    cors: {
      origin: "*", 
      methods: ["GET", "POST"]
    }
  });

  // Middleware: Authenticate Socket connection via JWT
  io.use((socket, next) => {
    const token = socket.handshake.auth.token;
    if (!token) {
      return next(new Error("Authentication error: Token missing"));
    }

    jwt.verify(token, process.env.JWT_SECRET, (err, decoded) => {
      if (err) {
        return next(new Error("Authentication error: Invalid token"));
      }
      socket.user = decoded; // Attach user info
      console.log("Decoded Token Data:", socket.user); 
      next();
    });
  });

  // Event Listeners
  io.on("connection", (socket) => {
    const currentUserId = socket.user._id || socket.user.id || socket.user.userId;
        if (!currentUserId) {
      console.error("[Socket Error] JWT Token does not contain a valid user ID! Token contents:", socket.user);
      return; 
    }
    console.log(`[Socket] User connected: ${socket.user.username}`); 

    // Fetch History using _id
    socket.on("chat:fetch_history", async () => {
      try {
        const history = await ChatMessage.find({ userId: currentUserId }) // Fixed _id
            .sort({ timestamp: 1 }) 
            .limit(50); 
        socket.emit("chat:history_loaded", history);
      } catch (err) {
        console.error("Error fetching history:", err);
      }
    });

    // Real-time contextual chat
    socket.on("chat:send", async (data) => {
      try {
        console.log(`[Chat] Received from user: ${data.message}`);
        socket.emit("chat:typing", { status: true });

        // 1. Fetch recent history
        let recentHistory = await ChatMessage.find({ userId: currentUserId }) // Fixed _id
            .sort({ timestamp: -1 })
            .limit(10)
            .lean(); 
            
        recentHistory = recentHistory.reverse(); 

        // 2. Request Gemini Contextual Reply FIRST
        const aiReply = await generateResponseWithHistory(data.message, recentHistory);

        // 3. Save BOTH messages to DB only if Gemini succeeds (prevents role-alternating crashes)
        const savedUserMessage = await ChatMessage.create({
          userId: currentUserId, // Fixed _id
          role: 'user',
          content: data.message
        });

        const savedAiMessage = await ChatMessage.create({
          userId: currentUserId, // Fixed _id
          role: 'model',
          content: aiReply
        });

        // 4. Emit processed message to UI
        socket.emit("chat:receive", {
          sender: "Mora",
          message: aiReply,
          timestamp: savedAiMessage.timestamp
        });
        
        socket.emit("chat:typing", { status: false });
      } catch (err) {
        console.error("Error processing message:", err);
        socket.emit("chat:typing", { status: false });
        // Optional: Emit an error message back to the user's UI here
      }
    });

    socket.on("disconnect", () => {
      console.log(`[Socket] User disconnected: ${socket.user.username}`);
    });
  });

  return io;
};

const getIo = () => {
  if (!io) {
    throw new Error("Socket.io not initialized!");
  }
  return io;
};

module.exports = { initSocket, getIo };
