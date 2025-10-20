const logger = require('../utils/logger');

const loggingMiddleware = (req, res, next) => {
  const start = Date.now();
  const { method, url } = req;
  const requestId = req.id;

  res.on('finish', () => {
    const duration = Date.now() - start;
    logger.info({
      requestId,
      method,
      url,
      statusCode: res.statusCode,
      duration,
    });
  });

  next();
};

module.exports = loggingMiddleware;
