require('dotenv').config();
const express = require('express');
const cors = require('cors');
const connectDB = require('./src/config/db');
const authRoutes = require('./src/routes/authRoutes');

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json()); // Parses incoming JSON requests

// Connect Database
connectDB();

// Routes
app.use('/api/auth', authRoutes);

// Basic test route
app.get('/', (req, res) => {
    res.send('🤖 Mora-Like AI Backend is Running!');
});

// Start Server
app.listen(PORT, () => {
    console.log(`🚀 Server running on http://localhost:${PORT}`);
});