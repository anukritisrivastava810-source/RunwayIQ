import request from 'supertest';
import app from '../src/app.js';
import prisma from '../src/config/prisma.js';

describe('Health & Observability Endpoints', () => {
  
  it('GET /health returns 200 OK', async () => {
    const res = await request(app).get('/health');
    expect(res.statusCode).toEqual(200);
    expect(res.body.status).toEqual('OK');
  });

  it('GET /health/liveness returns 200 ALIVE', async () => {
    const res = await request(app).get('/health/liveness');
    expect(res.statusCode).toEqual(200);
    expect(res.body.status).toEqual('ALIVE');
  });

  it('GET /health/readiness returns 200 when DB is connected', async () => {
    prisma.$queryRaw.mockResolvedValueOnce([{ '?column?': 1 }]);
    const res = await request(app).get('/health/readiness');
    expect(res.statusCode).toEqual(200);
    expect(res.body.database).toEqual('connected');
  });

  it('GET /health/readiness returns 503 when DB is disconnected', async () => {
    prisma.$queryRaw.mockRejectedValueOnce(new Error('DB Connection Refused'));
    const res = await request(app).get('/health/readiness');
    expect(res.statusCode).toEqual(503);
    expect(res.body.database).toEqual('disconnected');
  });

  it('GET /health/system returns system metrics', async () => {
    const res = await request(app).get('/health/system');
    expect(res.statusCode).toEqual(200);
    expect(res.body).toHaveProperty('memoryUsage');
    expect(res.body).toHaveProperty('cpuUsage');
    expect(res.body).toHaveProperty('uptime');
  });
});
