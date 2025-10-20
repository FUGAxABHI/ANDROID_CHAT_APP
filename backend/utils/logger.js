const pino = require('pino');
const crypto = require('crypto');

const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  mixin() {
    return { requestId: crypto.randomUUID() };
  },
  transport: {
    targets: [
      {
        target: 'pino-pretty',
        options: {
          colorize: true,
          translateTime: 'SYS:dd-mm-yyyy HH:MM:ss',
          ignore: 'pid,hostname,requestId',
        },
      },
      {
        target: 'pino/file',
        options: { destination: 'logs/app.log' },
      },
    ],
  },
});

module.exports = logger;
