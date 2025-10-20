const { Server } = require('socket.io');
const logger = require('../utils/logger');
const { registerChatHandlers } = require('./chatHandler');
const { registerCallHandlers } = require('./callHandler');
const Message = require('../models/Message');
const { socketAuthMiddleware } = require('../middleware/socketAuthMiddleware');

const { initFriendHandler } = require('./friendHandler');

const connectedUsers = {};

const initSocket = (server) => {
  const io = new Server(server, {
    cors: {
      origin: "*", // This should be restricted to your frontend's URL in production
      methods: ["GET", "POST"]
    }
  });

  // Initialize the friend handler with the io instance
  initFriendHandler(io, connectedUsers);

  // Use a shared middleware for authentication
  io.use(socketAuthMiddleware(connectedUsers));

  io.on('connection', (socket) => {
    logger.info(`[SocketManager] User connected: ${socket.user.username} (Socket ID: ${socket.id})`);

    // Announce that a new user has joined
    io.emit('user joined', socket.user.username);

    registerChatHandlers(io, socket, connectedUsers);
    registerCallHandlers(io, socket, connectedUsers);

    // Fetch and deliver any messages that were sent while the user was offline
    deliverOfflineMessages(socket);

    socket.on('disconnect', () => {
      if (socket.user && socket.user.username) {
        delete connectedUsers[socket.user.username];
        logger.info(`[SocketManager] User disconnected: ${socket.user.username}. Remaining users: ${Object.keys(connectedUsers).length}`);
        io.emit('user left', socket.user.username);
      }
    });
  });

  return io;
};

const deliverOfflineMessages = async (socket) => {
  logger.info(`[Offline Messages] Checking for offline messages for user: ${socket.user.username}`);
  try {
    const unreadMessages = await Message.find({ recipient: socket.user._id, isRead: false })
      .populate('sender', 'username')
      .sort({ timestamp: 1 });

    if (unreadMessages.length > 0) {
      logger.info(`[Offline Messages] Found ${unreadMessages.length} unread messages for ${socket.user.username}. Emitting as a single batch...`);
      socket.emit('private messages', unreadMessages);

      // Mark messages as delivered (isRead should be marked when the user actually reads them)
      await Message.updateMany(
        { _id: { $in: unreadMessages.map(msg => msg._id) } },
        { $set: { isRead: true } } // Or a new 'deliveredAt' field could be used
      );
      logger.info(`[Offline Messages] ${unreadMessages.length} messages for ${socket.user.username} marked as read.`);
    } else {
      logger.info(`[Offline Messages] No new messages for ${socket.user.username}.`);
    }
  } catch (error) {
    logger.error(`[Offline Messages] Error fetching/delivering unread messages for ${socket.user.username}: ${error.message}`);
  }
};

module.exports = { initSocket };
