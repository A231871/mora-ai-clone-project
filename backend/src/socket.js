const { Server } = require("socket.io");
const jwt = require("jsonwebtoken");
const { generateResponse } = require("./services/ai.service");

let io;

const initSocket = (server) => {
  io = new Server(server, {
    cors: {
      origin: "*", // Adjust this in production
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
      console.log("Decoded Token Data:", socket.user); // <--- ADD THIS LINE
      next();
    });
  });

  // Event Listeners
  io.on("connection", (socket) => {
    console.log(`[Socket] User connected: ${socket.user.username}`); // Adjusted because username may not be in token depending on how auth was handled in Phase 2

    // Listen for incoming chat messages from Flutter
    socket.on("chat:send", async (data) => {
      console.log(`[Chat] Received from user: ${data.message}`);
      
      // Emit acknowledging we are "typing/thinking"
      socket.emit("chat:typing", { status: true });

      // Call Gemini AI Service
      const aiReply = await generateResponse(data.message);

      // Emit response back to the specific user
      socket.emit("chat:receive", {
        sender: "Mora",
        message: aiReply,
        timestamp: new Date().toISOString()
      });
      
      socket.emit("chat:typing", { status: false });
    });

    socket.on("disconnect", () => {
      console.log(`[Socket] User disconnected: ${socket.user.id}`);
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
