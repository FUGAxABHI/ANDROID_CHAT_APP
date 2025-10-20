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

logger.info('Initializing application...');

// Add request ID
app.use((req, res, next) => {
  req.id = crypto.randomUUID();
  next();
});

// Logging middleware
logger.info('Registering logging middleware...');
app.use(loggingMiddleware);

// Initialize Socket.IO and pass the server instance
logger.info('Initializing Socket.IO...');
initSocket(server);

logger.info('Registering CORS and JSON middleware...');
app.use(cors());
app.use(express.json());

// Auth routes
logger.info('Registering auth routes...');
const authRoutes = require('./routes/auth');
app.use('/api/auth', authRoutes);

// User routes
logger.info('Registering user routes...');
const userRoutes = require('./routes/userRoutes');
app.use('/api/users', userRoutes);

// Friends routes
logger.info('Registering friends routes...');
const friendsRoutes = require('./routes/friends');
app.use('/api/friends', friendsRoutes);

// Chat routes
logger.info('Registering chat routes...');
const chatRoutes = require('./routes/chatRoutes');
app.use('/api/chat', chatRoutes);

// Upload routes
logger.info('Registering upload routes...');
const uploadRoutes = require('./routes/uploadRoutes');
app.use('/api/upload', uploadRoutes);

// Serve uploaded files
logger.info('Registering static file serving for /uploads and /images...');
app.use('/uploads', express.static('uploads'));
app.use('/images', express.static('images'));

app.get('/', (req, res) => {
  res.send('Backend is running!');
});

const PORT = process.env.PORT || 3000;

async function startServer() {
  logger.info('Starting server...');
  logger.info('Connecting to database...');
  await connectDB();
  logger.info('Database connected.');
  server.listen(PORT, () => {
    logger.info(`Server running on port ${PORT}`);
  });
}

startServer();
