const logger = require('../utils/logger');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

module.exports = async (req, res, next) => {
  logger.info('[AuthMiddleware] Auth middleware called.');
  const token = req.header('x-auth-token');
  logger.debug('[AuthMiddleware] Checking for token.');

  if (!token) {
    logger.warn('[AuthMiddleware] No token provided, authorization denied.');
    return res.status(401).json({ message: 'No token, authorization denied' });
  }

  try {
    logger.debug('[AuthMiddleware] Token found, attempting to verify.');
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    logger.debug(`[AuthMiddleware] Token verified successfully. Decoded payload: ${JSON.stringify(decoded)}`);

    logger.debug(`[AuthMiddleware] Finding user by ID: ${decoded.id}`);
    req.user = await User.findById(decoded.id);
    if (!req.user) {
      logger.warn(`[AuthMiddleware] User with ID ${decoded.id} not found.`);
      return res.status(401).json({ message: 'User not found, authorization denied' });
    }
    logger.info(`[AuthMiddleware] User authenticated: ${req.user.username}`);
    logger.info('[AuthMiddleware] Auth middleware finished, calling next().');
    next();
  } catch (error) {
    logger.error('[AuthMiddleware] Token is not valid:', error.message);
    res.status(401).json({ message: 'Token is not valid', error: error.message });
  }
};