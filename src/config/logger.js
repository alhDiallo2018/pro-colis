import pino from 'pino';
import { env } from './env.js';

const sensitiveKeys = [
  'password',
  'currentPassword',
  'newPassword',
  'pin',
  'currentPin',
  'newPin',
  'otpCode',
  'code',
  'token',
  'accessToken',
  'refreshToken',
  'authorization',
  'file'
];

export function sanitizeForLog(value) {
  if (!value || typeof value !== 'object') {
    return value;
  }

  if (Array.isArray(value)) {
    return value.map((item) => sanitizeForLog(item));
  }

  return Object.entries(value).reduce((safe, [key, item]) => {
    const isSensitive = sensitiveKeys.some((sensitiveKey) =>
      key.toLowerCase().includes(sensitiveKey.toLowerCase())
    );
    safe[key] = isSensitive ? '[REDACTED]' : sanitizeForLog(item);
    return safe;
  }, {});
}

export const logger = pino({
  level: env.LOG_LEVEL,
  redact: {
    paths: sensitiveKeys.map((key) => `*.${key}`),
    censor: '[REDACTED]'
  },
  transport:
    env.NODE_ENV === 'development'
      ? {
          target: 'pino-pretty',
          options: {
            colorize: true,
            translateTime: 'SYS:standard'
          }
        }
      : undefined
});
