import pinoHttp from 'pino-http';
import { logger, sanitizeForLog } from '../config/logger.js';

export const httpLogger = pinoHttp({
  logger,
  genReqId: (req) => req.requestId,
  customProps: (req) => ({
    requestId: req.requestId,
    userId: req.user?.id,
    role: req.user?.role
  }),
  serializers: {
    req(req) {
      return sanitizeForLog({
        id: req.id,
        method: req.method,
        url: req.url,
        body: req.raw?.body
      });
    }
  }
});
