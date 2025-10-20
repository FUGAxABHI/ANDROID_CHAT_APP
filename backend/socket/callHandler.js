
const logger = require('../utils/logger');

const registerCallHandlers = (io, socket, connectedUsers) => {
  socket.on('call-user', (data) => {
    logger.info(`[CallHandler] Received 'call-user' from ${socket.user.username} to ${data.to}`);
    const { to, from, signal } = data;
    const receiverSocketId = connectedUsers[to];
    if (receiverSocketId) {
      logger.info(`[CallHandler] Emitting 'call-made' to ${to} (Socket ID: ${receiverSocketId})`);
      io.to(receiverSocketId).emit('call-made', {
        signal,
        from,
      });
    } else {
      logger.warn(`[CallHandler] Receiver ${to} not found in connectedUsers.`);
      socket.emit('call-error', { message: 'User is not online.' });
    }
  });

  socket.on('make-answer', (data) => {
    logger.info(`[CallHandler] Received 'make-answer' from ${socket.user.username} to ${data.to}`);
    const { to, signal } = data;
    const receiverSocketId = connectedUsers[to];
    if (receiverSocketId) {
      logger.info(`[CallHandler] Emitting 'answer-made' to ${to} (Socket ID: ${receiverSocketId})`);
      io.to(receiverSocketId).emit('answer-made', {
        signal,
        from: socket.user.username,
      });
    } else {
      logger.warn(`[CallHandler] Receiver ${to} not found in connectedUsers.`);
    }
  });

  socket.on('ice-candidate', (data) => {
    logger.info(`[CallHandler] Received 'ice-candidate' from ${socket.user.username} to ${data.to}`);
    const { to, candidate } = data;
    const receiverSocketId = connectedUsers[to];
    if (receiverSocketId) {
      logger.info(`[CallHandler] Emitting 'ice-candidate' to ${to} (Socket ID: ${receiverSocketId})`);
      io.to(receiverSocketId).emit('ice-candidate', {
        candidate,
        from: socket.user.username,
      });
    } else {
      logger.warn(`[CallHandler] Receiver ${to} not found in connectedUsers.`);
    }
  });

  socket.on('call-rejected', (data) => {
    logger.info(`[CallHandler] Received 'call-rejected' from ${socket.user.username} to ${data.to}`);
    const { to } = data;
    const receiverSocketId = connectedUsers[to];
    if (receiverSocketId) {
      logger.info(`[CallHandler] Emitting 'call-rejected' to ${to} (Socket ID: ${receiverSocketId})`);
      io.to(receiverSocketId).emit('call-rejected', { from: socket.user.username });
    } else {
      logger.warn(`[CallHandler] Receiver ${to} not found in connectedUsers.`);
    }
  });

  socket.on('call-ended', (data) => {
    logger.info(`[CallHandler] Received 'call-ended' from ${socket.user.username} to ${data.to}`);
    const { to } = data;
    const receiverSocketId = connectedUsers[to];
    if (receiverSocketId) {
      logger.info(`[CallHandler] Emitting 'call-ended' to ${to} (Socket ID: ${receiverSocketId})`);
      io.to(receiverSocketId).emit('call-ended', { from: socket.user.username });
    } else {
      logger.warn(`[CallHandler] Receiver ${to} not found in connectedUsers.`);
    }
  });
};

module.exports = { registerCallHandlers };
