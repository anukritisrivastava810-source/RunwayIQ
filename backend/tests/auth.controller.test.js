import request from 'supertest';
import app from '../src/app.js';
import prisma from '../src/config/prisma.js';
import bcrypt from 'bcryptjs';

describe('Auth Controller', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('POST /api/v1/auth/login', () => {
    it('returns 200 and token for valid credentials', async () => {
      const password = 'password123';
      const hash = await bcrypt.hash(password, 10);
      
      prisma.user.findUnique.mockResolvedValueOnce({
        id: 'user-123',
        email: 'test@example.com',
        passwordHash: hash,
        role: 'FOUNDER',
        companyId: 'company-123'
      });

      const res = await request(app)
        .post('/api/v1/auth/login')
        .send({ email: 'test@example.com', password });

      expect(res.statusCode).toEqual(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.token).toBeDefined();
      expect(res.body.data.user.passwordHash).toBeUndefined();
    });

    it('returns 401 for invalid credentials', async () => {
      prisma.user.findUnique.mockResolvedValueOnce(null);

      const res = await request(app)
        .post('/api/v1/auth/login')
        .send({ email: 'test@example.com', password: 'wrong' });

      expect(res.statusCode).toEqual(401);
      expect(res.body.success).toBe(false);
    });
  });
});
