import request from 'supertest';
import { app } from '../src/app.js';

describe('auth middleware', () => {
  it('rejects protected routes without a bearer token', async () => {
    const response = await request(app).get('/api/v1/auth/me');

    expect(response.status).toBe(401);
    expect(response.body.success).toBe(false);
    expect(response.body.error.code).toBe('UNAUTHORIZED');
  });
});
