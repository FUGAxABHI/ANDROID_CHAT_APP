const jwt = require('jsonwebtoken');
const User = require('../models/User');
const logger = require('../utils/logger');

// socketAuthMiddleware.js
const socketAuthMiddleware = (connectedUsers) => async (socket, next) => {
    try {
        // Token can be sent via auth header or query param
        const token = socket.handshake.auth.token || socket.handshake.headers['x-auth-token'];
        logger.info(`[Socket Auth] Attempting to authenticate socket: ${socket.id}`);

        if (!token) {
            logger.error('[Socket Auth] Authentication error: No token provided.');
            return next(new Error('Authentication error: No token provided.'));
        }

        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        const user = await User.findById(decoded.id).select('-password');

        if (!user) {
            logger.error('[Socket Auth] Authentication error: User not found.');
            return next(new Error('Authentication error: User not found.'));
        }

        socket.user = user; // Attach user object to the socket instance
        connectedUsers[user.username] = socket.id; // Add user to the connected users list
        logger.info(`[Socket Auth] User '${user.username}' (ID: ${user.id}) authenticated and attached to socket. Socket ID: ${socket.id}`);

        logger.info(`[Socket Auth] User '${user.username}' authenticated successfully. Socket ID: ${socket.id}`);
        logger.info(`[Socket Auth] Connected users: ${JSON.stringify(Object.keys(connectedUsers))}`);
        next();
    } catch (error) {
        logger.error(`[Socket Auth] Authentication error: ${error.message}`);
        next(new Error('Authentication error: Invalid token.'));
    }
};

module.exports = { socketAuthMiddleware };
