import { ForbiddenError } from '../utils/errors.js';

export function requireRoles(...roles) {
  return (req, _res, next) => {
    if (!req.user || !roles.includes(req.user.role)) {
      return next(new ForbiddenError('Role insuffisant'));
    }

    return next();
  };
}
