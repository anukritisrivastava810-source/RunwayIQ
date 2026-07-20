import app from './app.js';
import { env } from './config/env.js';
import { logger } from './utils/logger.js';
import prisma from './config/prisma.js';

const PORT = env.port;

const server = app.listen(PORT, () => {
  logger.info('Server is running on port ' + PORT);
});

const gracefulShutdown = async () => {
  logger.info('Shutting down gracefully...');
  await prisma.$disconnect();
  server.close(() => {
    logger.info('Server closed.');
    process.exit(0);
  });
};

process.on('SIGTERM', gracefulShutdown);
process.on('SIGINT', gracefulShutdown);
