import { ZodError } from 'zod';
import { logger, sanitizeForLog } from '../config/logger.js';
import { env } from '../config/env.js';
import { fail } from '../utils/api-response.js';
import { ValidationError, normalizeError } from '../utils/errors.js';

export function notFoundMiddleware(req, res) {
  return fail(res, {
    status: 404,
    message: 'Route introuvable',
    code: 'NOT_FOUND',
    details: [{ path: req.originalUrl }]
  });
}

export function errorMiddleware(error, req, res, _next) {
  const normalizedError =
    error instanceof ZodError ? new ValidationError(error.issues) : normalizeError(error);

  if (!normalizedError) {
    logger.error(
      sanitizeForLog({
        error,
        requestId: req.requestId,
        path: req.originalUrl,
        userId: req.user?.id
      }),
      'Unhandled API error'
    );
  }

  const status = normalizedError?.statusCode || 500;
  return fail(res, {
    status,
    message:
      normalizedError?.publicMessage ||
      (env.NODE_ENV === 'production' ? 'Erreur serveur' : error.message),
    code: normalizedError?.code || 'INTERNAL_ERROR',
    details: normalizedError?.details || []
  });
}
