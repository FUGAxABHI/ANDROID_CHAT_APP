const logger = require('../utils/logger');

const loggingMiddleware = (req, res, next) => {
  const start = Date.now();
  const { method, url, headers } = req;
  const requestId = req.id;
  const userAgent = headers['user-agent'];

  logger.info(`[Request] ${requestId} - ${method} ${url} - User-Agent: ${userAgent}`);

  if (process.env.NODE_ENV !== 'production' && req.body) {
    logger.debug(`[Request Body] ${requestId} - ${JSON.stringify(req.body)}`);
  }

  res.on('finish', () => {
    const duration = Date.now() - start;
    logger.info(`[Response] ${requestId} - ${method} ${url} - ${res.statusCode} - ${duration}ms`);
  });

  next();
};

module.exports = loggingMiddleware;
