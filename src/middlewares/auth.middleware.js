import { prisma } from '../config/prisma.js';
import { UnauthorizedError, ForbiddenError } from '../utils/errors.js';
import { verifyAccessToken } from '../utils/tokens.js';

export async function authenticate(req, _res, next) {
  try {
    const header = req.headers.authorization;
    const [, token] = header?.split(' ') || [];

    if (!token) {
      throw new UnauthorizedError('Token absent');
    }

    const payload = verifyAccessToken(token);
    const user = await prisma.user.findUnique({ where: { id: payload.sub } });

    if (!user || user.status !== 'active') {
      throw new UnauthorizedError('Session invalide');
    }

    req.user = user;
    return next();
  } catch (error) {
    if (error.statusCode) {
      return next(error);
    }
    return next(new UnauthorizedError('Token invalide'));
  }
}

export function optionalAuthenticate(req, res, next) {
  if (!req.headers.authorization) {
    return next();
  }
  return authenticate(req, res, next);
}

export function ensureActiveUser(req, _res, next) {
  if (!req.user || req.user.status !== 'active') {
    return next(new ForbiddenError('Compte inactif'));
  }
  return next();
}
