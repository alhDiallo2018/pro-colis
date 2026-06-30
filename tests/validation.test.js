import request from 'supertest';
import { app } from '../src/app.js';

describe('validation middleware', () => {
  it('rejects invalid register payloads', async () => {
    const response = await request(app).post('/api/v1/auth/register').send({
      phone: '12',
      fullName: 'A'
    });

    expect(response.status).toBe(422);
    expect(response.body.success).toBe(false);
    expect(response.body.error.code).toBe('VALIDATION_ERROR');
  });
});
