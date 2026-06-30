import crypto from 'node:crypto';

export function generateTrackingNumber(date = new Date()) {
  const stamp = date.toISOString().slice(0, 10).replaceAll('-', '');
  const suffix = crypto.randomBytes(4).toString('hex').slice(0, 6).toUpperCase();
  return `PC-${stamp}-${suffix}`;
}
