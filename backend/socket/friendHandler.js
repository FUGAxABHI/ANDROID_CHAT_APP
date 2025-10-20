const logger = require('../utils/logger');

let io;
let connectedUsers;

const initFriendHandler = (socketIo, users) => {
  io = socketIo;
  connectedUsers = users;
  logger.info('Friend handler initialized');
  logger.debug(`Initial connected users: ${JSON.stringify(Object.keys(connectedUsers))}`);
};

const notifyFriendRequest = (receiverUsername, request) => {
  const receiverSocketId = connectedUsers[receiverUsername];
  if (receiverSocketId) {
    io.to(receiverSocketId).emit('new_friend_request', request);
    logger.info(`Notified ${receiverUsername} of new friend request.`);
  } else {
    logger.info(`User ${receiverUsername} is not connected. Cannot send friend request notification.`);
  }
};

const notifyRequestAccepted = (senderUsername, newFriend) => {
  const senderSocketId = connectedUsers[senderUsername];
  if (senderSocketId) {
    io.to(senderSocketId).emit('friend_request_accepted', newFriend);
    logger.info(`Notified ${senderUsername} that their request was accepted.`);
  } else {
    logger.info(`User ${senderUsername} is not connected. Cannot send friend request accepted notification.`);
  }
};

module.exports = { initFriendHandler, notifyFriendRequest, notifyRequestAccepted };
