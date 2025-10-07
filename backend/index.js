const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
require('dotenv').config();
const { connectDB } = require('./config/db');
const logger = require('./utils/logger');
const jwt = require('jsonwebtoken');
const User = require('./models/User');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*", // Allow all origins for now, refine later
    methods: ["GET", "POST"]
  }
});

const socketAuthMiddleware = async (socket, next) => {
  try {
    const token = socket.handshake.auth.token || socket.handshake.headers['x-auth-token'];
    logger.info(`[Auth Middleware] Received token: ${token ? 'present' : 'absent'}`);

    if (!token) {
      logger.error('[Auth Middleware] Authentication error: No token provided.');
      return next(new Error('Authentication error: No token provided.'));
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    socket.user = await User.findById(decoded.id).select('-password'); // Attach user to socket
    if (!socket.user) {
      logger.error('[Auth Middleware] Authentication error: User not found for decoded ID.');
      return next(new Error('Authentication error: User not found.'));
    }
    connectedUsers[socket.user.username] = socket.id; // Update connectedUsers here
    logger.info(`[Auth Middleware] User ${socket.user.username} authenticated successfully. connectedUsers: ${JSON.stringify(connectedUsers)}`);
    next();
  } catch (error) {
    logger.error(`[Auth Middleware] Authentication error: ${error.message}`);
    next(new Error('Authentication error: Invalid token.'));
  }
};

io.use(socketAuthMiddleware);

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

app.get('/', (req, res) => {
  res.send('Backend is running!');
});

const Message = require('./models/Message');
const connectedUsers = {};

io.on('connection', (socket) => {
  logger.info('a user connected');

  if (socket.user) {
    socket.username = socket.user.username;
    // connectedUsers[socket.username] is already set in auth middleware
    logger.info(`[Connected Users] User ${socket.username} (ID: ${socket.id}) connected. connectedUsers: ${JSON.stringify(connectedUsers)}`);
    io.emit('user joined', socket.username);

    // Fetch and send unread messages to the newly connected user
    (async () => {
      try {
        const unreadMessages = await Message.find({ recipient: socket.user._id, isRead: false }).populate('sender', 'username').sort({ timestamp: 1 });
        if (unreadMessages.length > 0) {
          logger.info(`[Offline Messages] Found ${unreadMessages.length} unread messages for ${socket.username}. Emitting...`);
          for (const msg of unreadMessages) {
            socket.emit('private message', { message: msg });
          }
          // Mark these messages as read after emitting
          await Message.updateMany({ _id: { $in: unreadMessages.map(msg => msg._id) } }, { $set: { isRead: true } });
          logger.info(`[Offline Messages] ${unreadMessages.length} messages marked as read for ${socket.username}.`);
        }
      } catch (error) {
        logger.error(`[Offline Messages] Error fetching/emitting unread messages for ${socket.username}: ${error.message}`);
      }
    })();

  } else {
    logger.warning(`A user connected without authentication. Socket ID: ${socket.id}. This should not happen if auth middleware is working correctly.`);
  }

  socket.on('message history', async () => {
    if (!socket.user) { // Ensure user is authenticated
      logger.error('Attempted to get message history without authenticated user.');
      return;
    }
    try {
      const messages = await Message.find({ receiver: 'all' }).sort({ timestamp: 1 });
      socket.emit('message history', messages);
    } catch (error) {
      logger.error('Error fetching message history:', error);
    }
  });

  socket.on('chat message', async (msg) => {
    if (!socket.user) { // Ensure user is authenticated
      logger.error('Attempted to send chat message without authenticated user.');
      return;
    }
    const message = new Message({ sender: socket.user._id, message: msg });
    await message.save();
    const populatedMessage = await Message.findById(message._id).populate('sender', 'username');
    io.emit('chat message', { username: populatedMessage.sender.username, message: populatedMessage.message });
  });

  socket.on('get private messages', async ({ withUser }) => {
    if (!socket.user) { // Ensure user is authenticated
      logger.error('Attempted to get private messages without authenticated user.');
      return;
    }
    try {
      logger.info(`Getting private messages for ${socket.user.username} with ${withUser}`);
      const withUserDoc = await User.findOne({ username: withUser });
      if (!withUserDoc) {
        return logger.error(`User ${withUser} not found`);
      }
      const messages = await Message.find({
        $or: [
          { sender: socket.user._id, recipient: withUserDoc._id },
          { sender: withUserDoc._id, recipient: socket.user._id },
        ],
      }).sort({ timestamp: 1 }).populate('sender', 'username');
      logger.info(`Found ${messages.length} messages`);
      socket.emit('private messages', messages);
    } catch (error) {
      logger.error('Error fetching private messages:', error);
    }
  });

  socket.on('typing', ({ to }) => {
    const receiverSocketId = connectedUsers[to];
    if (receiverSocketId) {
      io.to(receiverSocketId).emit('typing', { from: socket.user.username });
    }
  });

  socket.on('stop typing', ({ to }) => {
    const receiverSocketId = connectedUsers[to];
    if (receiverSocketId) {
      io.to(receiverSocketId).emit('stop typing', { from: socket.user.username });
    }
  });

  socket.on('mark messages as read', async ({ withUser }) => {
    if (!socket.user) {
        logger.error('Attempted to mark messages as read without authenticated user.');
        return;
    }
    try {
        const withUserDoc = await User.findOne({ username: withUser });
        if (!withUserDoc) {
          return logger.error(`User ${withUser} not found`);
        }
        await Message.updateMany(
            { sender: withUserDoc._id, recipient: socket.user._id, isRead: false },
            { $set: { isRead: true } }
        );
        const senderSocketId = connectedUsers[withUser];
        if (senderSocketId) {
            io.to(senderSocketId).emit('messages marked as read', { byUser: socket.user.username });
        }
    } catch (error) {
        logger.error('Error marking messages as read:', error);
    }
  });

  socket.on('private message', async (data) => {
    logger.info(`[Private Message] Received from ${socket.user.username}: ${JSON.stringify(data)}`);
    if (!socket.user) { // Ensure user is authenticated
      logger.error('[Private Message] Attempted to send private message without authenticated user.');
      return;
    }
    const { to, message, isVoice, voiceData } = data;
    const recipientUser = await User.findOne({ username: to });
    if (!recipientUser) {
      logger.error(`[Private Message] Recipient user ${to} not found.`);
      return;
    }
    logger.info(`[Private Message] Recipient user found: ${recipientUser.username}`);

    const newMessage = new Message({
      sender: socket.user._id,
      recipient: recipientUser._id,
      message,
      isVoice,
      voiceData,
    });
    await newMessage.save();
    const populatedMessage = await Message.findById(newMessage._id).populate('sender', 'username');
    logger.info(`[Private Message] Message saved and populated: ${JSON.stringify(populatedMessage)}`);

    const receiverSocketId = connectedUsers[recipientUser.username];
    if (receiverSocketId) {
      logger.info(`[Private Message] Recipient ${recipientUser.username} is online. Emitting to socket ID: ${receiverSocketId}`);
      io.to(receiverSocketId).emit('private message', { message: populatedMessage });
    } else {
      logger.info(`[Private Message] Recipient ${recipientUser.username} is offline. Message saved, but not emitted in real-time.`);
    }
  });

  socket.on('disconnect', () => {
    if (socket.user && socket.user.username) {
      delete connectedUsers[socket.user.username];
      logger.info(`[Connected Users] User ${socket.user.username} disconnected. connectedUsers: ${JSON.stringify(connectedUsers)}`);
      io.emit('user left', socket.user.username);
    }
    logger.info('user disconnected');
  });
});

const PORT = process.env.PORT || 3000;

async function startServer() {
  await connectDB();
  server.listen(PORT, () => {
    logger.info(`Server running on port ${PORT}`);
  });
}

startServer();
