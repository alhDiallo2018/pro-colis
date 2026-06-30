import request from 'supertest';
import { app } from '../src/app.js';

describe('login route', () => {
  it('exposes /auth/login as a validated login endpoint', async () => {
    const response = await request(app).post('/api/v1/auth/login').send({
      identifier: 'customer@procolis.test',
      pin: '1234'
    });

    expect(response.status).toBe(422);
    expect(response.body.error.code).toBe('VALIDATION_ERROR');
  });
});
