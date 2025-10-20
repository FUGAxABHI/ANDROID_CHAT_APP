const express = require('express');
const http = require('http');
const cors = require('cors');
require('dotenv').config();
const { connectDB } = require('./config/db');
const logger = require('./utils/logger');
const { initSocket } = require('./socket/socketManager');
const loggingMiddleware = require('./middleware/loggingMiddleware');
const crypto = require('crypto');

const app = express();
const server = http.createServer(app);

// Add request ID
app.use((req, res, next) => {
  req.id = crypto.randomUUID();
  next();
});

// Logging middleware
app.use(loggingMiddleware);

// Initialize Socket.IO and pass the server instance
initSocket(server);

app.use(cors());
app.use(express.json());

// Auth routes
const authRoutes = require('./routes/auth');
app.use('/api/auth', authRoutes);

// User routes
const userRoutes = require('./routes/userRoutes');
app.use('/api/users', userRoutes);

// Friends routes
const friendsRoutes = require('./routes/friends');
app.use('/api/friends', friendsRoutes);

// Chat routes
const chatRoutes = require('./routes/chatRoutes');
app.use('/api/chat', chatRoutes);

// Upload routes
const uploadRoutes = require('./routes/uploadRoutes');
app.use('/api/upload', uploadRoutes);

// Serve uploaded files
app.use('/uploads', express.static('uploads'));
app.use('/images', express.static('images'));

app.get('/', (req, res) => {
  res.send('Backend is running!');
});

const PORT = process.env.PORT || 3000;

async function startServer() {
  await connectDB();
  server.listen(PORT, () => {
    logger.info(`Server running on port ${PORT}`);
  });
}

startServer();
