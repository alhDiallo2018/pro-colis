import { Router } from 'express';
import { ok } from '../../utils/api-response.js';

export const healthRouter = Router();

healthRouter.get('/', (_req, res) =>
  ok(res, {
    message: 'API operationnelle',
    data: {
      data: {
        service: 'procolis-api',
        status: 'ok',
        timestamp: new Date().toISOString()
      }
    }
  })
);
