const Message = require('../models/Message');
const User = require('../models/User');
const logger = require('../utils/logger');

// This object will be managed by the main socket handler
// to keep track of all connected users.
const registerChatHandlers = (io, socket, connectedUsers) => {
  // Handler for fetching message history (example, can be expanded)
  socket.on('message history', async () => {
    if (!socket.user) {
      logger.error('Attempted to get message history without authenticated user.');
      return;
    }
    try {
      // Example: fetching public messages. This should be adapted for specific chat rooms.
      const messages = await Message.find({ recipient: 'all' }).sort({ timestamp: 1 }).populate('sender', 'username');
      socket.emit('message history', messages);
    } catch (error) {
      logger.error('Error fetching message history:', error);
    }
  });

  // Handler for one-on-one private messages
  socket.on('private message', async (data) => {
    logger.info(`[Private Message] Received from ${socket.user.username}: ${JSON.stringify(data)}`);
    if (!socket.user) {
      logger.error('[Private Message] Attempted to send private message without authenticated user.');
      return;
    }

    const { to, message, isVoice, voiceData } = data;
    const recipientUser = await User.findOne({ username: to });

    if (!recipientUser) {
      logger.error(`[Private Message] Recipient user ${to} not found.`);
      // Optionally, emit an error back to the sender
      socket.emit('error', { message: `User ${to} not found.` });
      return;
    }

    logger.info(`[Private Message] Recipient user found: ${recipientUser.username}`);

    try {
      const newMessage = new Message({
        sender: socket.user._id,
        recipient: recipientUser._id,
        message,
        // The schema needs to be updated to handle these fields properly
        // isVoice,
        // voiceData,
      });
      await newMessage.save();
      const populatedMessage = await Message.findById(newMessage._id).populate('sender', 'username');
      logger.info(`[Private Message] Message saved and populated: ${JSON.stringify(populatedMessage)}`);

      const receiverSocketId = connectedUsers[recipientUser.username];
      if (receiverSocketId) {
        logger.info(`[Private Message] Recipient ${recipientUser.username} is online. Emitting to socket ID: ${receiverSocketId}`);
        io.to(receiverSocketId).emit('private message', { message: populatedMessage });
      } else {
        logger.info(`[Private Message] Recipient ${recipientUser.username} is offline. Message will be delivered upon next connection.`);
      }
      // Also send the message back to the sender to confirm it was sent
      socket.emit('private message', { message: populatedMessage });

    } catch (error) {
        logger.error(`[Private Message] Error saving or sending message: ${error.message}`);
        socket.emit('error', { message: 'Failed to send message.' });
    }
  });

  // Handler for fetching the message history with a specific user
  socket.on('get private messages', async ({ withUser }) => {
    if (!socket.user) {
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
        // Notify the other user that their messages have been read
        const senderSocketId = connectedUsers[withUser];
        if (senderSocketId) {
            io.to(senderSocketId).emit('messages marked as read', { byUser: socket.user.username, withUser: socket.user.username });
        }
    } catch (error) {
        logger.error('Error marking messages as read:', error);
    }
  });
};

module.exports = { registerChatHandlers };
