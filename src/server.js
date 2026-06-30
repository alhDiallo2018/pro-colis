import { app } from './app.js';
import { env } from './config/env.js';
import { logger } from './config/logger.js';
import { disconnectPrisma } from './config/prisma.js';

const server = app.listen(env.PORT, () => {
  logger.info({ port: env.PORT }, 'PRO COLIS API started');
});

async function shutdown(signal) {
  logger.info({ signal }, 'Stopping PRO COLIS API');
  server.close(async () => {
    await disconnectPrisma();
    process.exit(0);
  });
}

process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);
