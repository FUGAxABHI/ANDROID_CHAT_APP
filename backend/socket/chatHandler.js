const Message = require('../models/Message');
const User = require('../models/User');
const logger = require('../utils/logger');

// This object will be managed by the main socket handler
// to keep track of all connected users.
const registerChatHandlers = (io, socket, connectedUsers) => {
  // Handler for fetching message history
  socket.on('message history', async () => {
    if (!socket.user) {
      logger.error('[ChatHandler] Attempted to get message history without authenticated user.');
      return;
    }
    logger.info(`[ChatHandler] User ${socket.user.username} requested message history.`);
    try {
      const messages = await Message.find({ recipient: 'all' }).sort({ timestamp: 1 }).populate('sender', 'username');
      socket.emit('message history', messages);
      logger.info(`[ChatHandler] Sent ${messages.length} messages to ${socket.user.username}.`);
    } catch (error) {
      logger.error('[ChatHandler] Error fetching message history:', error.message, error.stack);
    }
  });

  // Handler for one-on-one private messages
  socket.on('private message', async (data) => {
    if (!socket.user) {
      logger.error('[ChatHandler] Attempted to send private message without authenticated user.');
      return;
    }
    logger.info(`[ChatHandler] Received private message from ${socket.user.username} to ${data.to}: ${data.message}`);

    const { to, message, isVoice, voiceData } = data;
    const recipientUser = await User.findOne({ username: to });

    if (!recipientUser) {
      logger.error(`[ChatHandler] Recipient user ${to} not found.`);
      socket.emit('error', { message: `User ${to} not found.` });
      return;
    }

    try {
      const newMessage = new Message({
        sender: socket.user._id,
        recipient: recipientUser._id,
        message,
      });
      await newMessage.save();
      const populatedMessage = await Message.findById(newMessage._id).populate('sender', 'username');
      logger.info(`[ChatHandler] Message saved to DB: ${populatedMessage._id}`);

      const receiverSocketId = connectedUsers[recipientUser.username];
      if (receiverSocketId) {
        logger.info(`[ChatHandler] Recipient ${recipientUser.username} is online. Emitting to socket ID: ${receiverSocketId}`);
        io.to(receiverSocketId).emit('private message', { message: populatedMessage });
      } else {
        logger.info(`[ChatHandler] Recipient ${recipientUser.username} is offline.`);
      }
      socket.emit('private message', { message: populatedMessage });

    } catch (error) {
        logger.error(`[ChatHandler] Error sending private message: ${error.message}`, error.stack);
        socket.emit('error', { message: 'Failed to send message.' });
    }
  });

  // Handler for fetching the message history with a specific user
  socket.on('get private messages', async ({ withUser }) => {
    if (!socket.user) {
      logger.error('[ChatHandler] Attempted to get private messages without authenticated user.');
      return;
    }
    logger.info(`[ChatHandler] User ${socket.user.username} requested private messages with ${withUser}.`);
    try {
      const withUserDoc = await User.findOne({ username: withUser });
      if (!withUserDoc) {
        logger.error(`[ChatHandler] User ${withUser} not found`);
        return;
      }
      const messages = await Message.find({
        $or: [
          { sender: socket.user._id, recipient: withUserDoc._id },
          { sender: withUserDoc._id, recipient: socket.user._id },
        ],
      }).sort({ timestamp: 1 }).populate('sender', 'username');
      logger.info(`[ChatHandler] Found ${messages.length} private messages between ${socket.user.username} and ${withUser}.`);
      socket.emit('private messages', messages);
    } catch (error) {
      logger.error('[ChatHandler] Error fetching private messages:', error.message, error.stack);
    }
  });

  // Handler for 'typing' notification
  socket.on('typing', ({ to }) => {
    if (!socket.user) return;
    const receiverSocketId = connectedUsers[to];
    if (receiverSocketId) {
      io.to(receiverSocketId).emit('typing', { from: socket.user.username });
    }
  });

  // Handler for 'stop typing' notification
  socket.on('stop typing', ({ to }) => {
    if (!socket.user) return;
    const receiverSocketId = connectedUsers[to];
    if (receiverSocketId) {
      io.to(receiverSocketId).emit('stop typing', { from: socket.user.username });
    }
  });

  // Handler for marking messages as read
  socket.on('mark messages as read', async ({ withUser }) => {
    if (!socket.user) {
        logger.error('[ChatHandler] Attempted to mark messages as read without authenticated user.');
        return;
    }
    logger.info(`[ChatHandler] User ${socket.user.username} is marking messages with ${withUser} as read.`);
    try {
        const withUserDoc = await User.findOne({ username: withUser });
        if (!withUserDoc) {
          logger.error(`[ChatHandler] User ${withUser} not found`);
          return;
        }
        const updateResult = await Message.updateMany(
            { sender: withUserDoc._id, recipient: socket.user._id, isRead: false },
            { $set: { isRead: true } }
        );
        logger.info(`[ChatHandler] Marked ${updateResult.nModified || 0} messages as read.`);
        const senderSocketId = connectedUsers[withUser];
        if (senderSocketId) {
            io.to(senderSocketId).emit('messages marked as read', { byUser: socket.user.username, withUser: socket.user.username });
        }
    } catch (error) {
        logger.error('[ChatHandler] Error marking messages as read:', error.message, error.stack);
    }
  });
};

module.exports = { registerChatHandlers };
