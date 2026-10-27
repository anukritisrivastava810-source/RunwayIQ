import request from 'supertest';
import jwt from 'jsonwebtoken';
import app from '../src/app.js';
import prisma from '../src/config/prisma.js';

describe('Scenario Controller & Service — Company Scope & Simulation', () => {
  const companyAId = 'a0000000-0000-0000-0000-000000000001';
  const companyBId = 'b0000000-0000-0000-0000-000000000002';
  const scenarioAId = 'c0000000-0000-0000-0000-000000000001';

  const createAuthToken = (companyId, role = 'FOUNDER', id = 'user-123') => {
    return jwt.sign(
      { id, email: 'founder@test.com', role, companyId },
      process.env.JWT_SECRET || 'test_secret',
      { expiresIn: '1h' }
    );
  };

  const tokenCompanyA = createAuthToken(companyAId);
  const tokenCompanyB = createAuthToken(companyBId);

  beforeEach(() => {
    jest.clearAllMocks();
  });

  // =========================================================================
  // Authentication & Unauthorized Requests
  // =========================================================================
  describe('Authentication & Authorization', () => {
    it('returns 401 when no token is provided for GET /company/:companyId', async () => {
      const res = await request(app).get(`/api/v1/scenarios/company/${companyAId}`);
      expect(res.statusCode).toBe(401);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toMatch(/Not authorized/i);
    });

    it('returns 401 when invalid Bearer token is provided', async () => {
      const res = await request(app)
        .get(`/api/v1/scenarios/company/${companyAId}`)
        .set('Authorization', 'Bearer invalid-token');
      expect(res.statusCode).toBe(401);
      expect(res.body.success).toBe(false);
    });

    it('returns 401 when no token is provided for POST /simulate', async () => {
      const res = await request(app)
        .post('/api/v1/scenarios/simulate')
        .send({ companyId: companyAId });
      expect(res.statusCode).toBe(401);
      expect(res.body.success).toBe(false);
    });

    it('returns 403 Forbidden when user from Company B requests scenarios of Company A', async () => {
      const res = await request(app)
        .get(`/api/v1/scenarios/company/${companyAId}`)
        .set('Authorization', `Bearer ${tokenCompanyB}`);

      expect(res.statusCode).toBe(403);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toMatch(/Forbidden/i);
    });

    it('returns 403 Forbidden when user from Company B attempts simulation for Company A', async () => {
      const res = await request(app)
        .post('/api/v1/scenarios/simulate')
        .set('Authorization', `Bearer ${tokenCompanyB}`)
        .send({ companyId: companyAId });

      expect(res.statusCode).toBe(403);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toMatch(/Forbidden/i);
    });
  });

  // =========================================================================
  // Company-Scoped Scenario Retrieval (GET /company/:companyId)
  // =========================================================================
  describe('GET /api/v1/scenarios/company/:companyId', () => {
    it('returns 400 for an invalid company UUID format', async () => {
      const res = await request(app)
        .get('/api/v1/scenarios/company/not-a-uuid')
        .set('Authorization', `Bearer ${tokenCompanyA}`);

      expect(res.statusCode).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toMatch(/Invalid company ID/i);
    });

    it('returns 404 when company does not exist', async () => {
      prisma.company.findUnique.mockResolvedValueOnce(null);

      const res = await request(app)
        .get(`/api/v1/scenarios/company/${companyAId}`)
        .set('Authorization', `Bearer ${tokenCompanyA}`);

      expect(res.statusCode).toBe(404);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toMatch(/Company not found/i);
    });

    it('retrieves scenarios for a valid company', async () => {
      prisma.company.findUnique.mockResolvedValueOnce({
        id: companyAId,
        name: 'Company A',
      });
      prisma.scenario.findMany.mockResolvedValueOnce([
        {
          id: scenarioAId,
          companyId: companyAId,
          name: 'Conservative Growth',
          baseCash: '500000',
          baseMonthlyBurn: '25000',
          baseRunwayMonths: '20',
          simulatedRunway: '18',
        },
      ]);

      const res = await request(app)
        .get(`/api/v1/scenarios/company/${companyAId}`)
        .set('Authorization', `Bearer ${tokenCompanyA}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data).toHaveLength(1);
      expect(res.body.data[0].id).toBe(scenarioAId);
      expect(res.body.data[0].companyId).toBe(companyAId);
      expect(prisma.scenario.findMany).toHaveBeenCalledWith({
        where: { companyId: companyAId },
      });
    });

    it('returns empty array when company exists but has no scenarios', async () => {
      prisma.company.findUnique.mockResolvedValueOnce({
        id: companyAId,
        name: 'Company A',
      });
      prisma.scenario.findMany.mockResolvedValueOnce([]);

      const res = await request(app)
        .get(`/api/v1/scenarios/company/${companyAId}`)
        .set('Authorization', `Bearer ${tokenCompanyA}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data).toEqual([]);
    });

    it('ensures scenarios from another company are not returned', async () => {
      prisma.company.findUnique.mockResolvedValueOnce({
        id: companyAId,
        name: 'Company A',
      });
      // Mock repository only returning scenarios with companyAId
      prisma.scenario.findMany.mockResolvedValueOnce([
        { id: scenarioAId, companyId: companyAId, name: 'Scenario A' },
      ]);

      const res = await request(app)
        .get(`/api/v1/scenarios/company/${companyAId}`)
        .set('Authorization', `Bearer ${tokenCompanyA}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.data.every(s => s.companyId === companyAId)).toBe(true);
      expect(res.body.data.some(s => s.companyId === companyBId)).toBe(false);
    });
  });

  // =========================================================================
  // Scenarios General Endpoint (GET /api/v1/scenarios) Isolation
  // =========================================================================
  describe('GET /api/v1/scenarios company isolation', () => {
    it('scopes listing to authenticated user company without exposing other companies', async () => {
      prisma.company.findUnique.mockResolvedValueOnce({
        id: companyAId,
        name: 'Company A',
      });
      prisma.scenario.findMany.mockResolvedValueOnce([
        { id: scenarioAId, companyId: companyAId, name: 'Company A Scenario' },
      ]);

      const res = await request(app)
        .get('/api/v1/scenarios')
        .set('Authorization', `Bearer ${tokenCompanyA}`);

      expect(res.statusCode).toBe(200);
      expect(prisma.scenario.findMany).toHaveBeenCalledWith({
        where: { companyId: companyAId },
      });
      expect(res.body.data).toHaveLength(1);
    });

    it('rejects attempt to query another company via ?companyId query param', async () => {
      const res = await request(app)
        .get(`/api/v1/scenarios?companyId=${companyBId}`)
        .set('Authorization', `Bearer ${tokenCompanyA}`);

      expect(res.statusCode).toBe(403);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toMatch(/Forbidden/i);
    });
  });

  // =========================================================================
  // Scenario Simulation (POST /api/v1/scenarios/simulate)
  // =========================================================================
  describe('POST /api/v1/scenarios/simulate', () => {
    const mockBaselineData = (cash = 300000, monthlyPayroll = 20000, monthlyExpenses = 10000) => {
      prisma.company.findUnique.mockResolvedValue({
        id: companyAId,
        name: 'Company A',
        currency: 'USD',
      });
      // Baseline Cash calculation: funding - expenses
      prisma.fundingRound.aggregate.mockResolvedValue({
        _sum: { amountRaised: cash + 100000 },
      });
      prisma.expense.aggregate
        .mockResolvedValueOnce({ _sum: { amount: 100000 } }) // for getCurrentCash
        .mockResolvedValueOnce({ _sum: { amount: monthlyExpenses } }); // for getMonthlyBurnRate
      // Baseline Burn calculation: monthlyPayroll + monthlyExpenses
      prisma.employee.aggregate.mockResolvedValue({
        _sum: { annualSalary: monthlyPayroll * 12 },
      });
    };

    it('performs successful simulation with valid inputs', async () => {
      mockBaselineData(300000, 20000, 10000); // baseCash = 300k, baseBurn = 30k, baseRunway = 10 months

      const payload = {
        companyId: companyAId,
        additionalBurn: 10000,
        additionalRevenue: 5000,
        additionalCash: 50000,
      };

      const res = await request(app)
        .post('/api/v1/scenarios/simulate')
        .set('Authorization', `Bearer ${tokenCompanyA}`)
        .send(payload);

      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);

      const { baseline, simulated, adjustments, companyId } = res.body.data;
      expect(companyId).toBe(companyAId);

      // Baseline checks
      expect(baseline.cash).toBe(300000);
      expect(baseline.burn).toBe(30000);
      expect(baseline.runway).toBe(10);

      // Simulated checks
      // Cash: 300,000 + 50,000 = 350,000
      expect(simulated.cash).toBe(350000);
      // Burn: 30,000 + 10,000 - 5,000 = 35,000
      expect(simulated.burn).toBe(35000);
      // Runway: 350,000 / 35,000 = 10 months
      expect(simulated.runway).toBe(10);

      expect(adjustments.additionalBurn).toBe(10000);
      expect(adjustments.additionalRevenue).toBe(5000);
      expect(adjustments.additionalCash).toBe(50000);

      // Verify that simulation did NOT persist a scenario
      expect(prisma.scenario.create).not.toHaveBeenCalled();
    });

    it('handles simulation referencing an existing scenario', async () => {
      prisma.scenario.findUnique.mockResolvedValueOnce({
        id: scenarioAId,
        companyId: companyAId,
        name: 'Existing Plan',
        additionalBurn: '5000',
        additionalRevenue: '2000',
        additionalCash: '20000',
      });
      mockBaselineData(200000, 15000, 5000); // baseCash = 200k, baseBurn = 20k

      const res = await request(app)
        .post('/api/v1/scenarios/simulate')
        .set('Authorization', `Bearer ${tokenCompanyA}`)
        .send({ scenarioId: scenarioAId });

      expect(res.statusCode).toBe(200);
      expect(res.body.data.scenarioId).toBe(scenarioAId);
      expect(res.body.data.scenarioName).toBe('Existing Plan');
      expect(res.body.data.adjustments.additionalBurn).toBe(5000);
      expect(res.body.data.adjustments.additionalRevenue).toBe(2000);
      expect(res.body.data.adjustments.additionalCash).toBe(20000);
    });

    it('returns 400 when missing both companyId and scenarioId', async () => {
      const res = await request(app)
        .post('/api/v1/scenarios/simulate')
        .set('Authorization', `Bearer ${tokenCompanyA}`)
        .send({ additionalBurn: 5000 });

      expect(res.statusCode).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toMatch(/Validation Error|Either companyId or scenarioId/i);
    });

    it('returns 400 when non-numeric adjustment inputs are supplied', async () => {
      const res = await request(app)
        .post('/api/v1/scenarios/simulate')
        .set('Authorization', `Bearer ${tokenCompanyA}`)
        .send({
          companyId: companyAId,
          additionalBurn: 'not-a-number',
        });

      expect(res.statusCode).toBe(400);
      expect(res.body.success).toBe(false);
    });

    it('returns 400 when companyId is not a valid UUID', async () => {
      const res = await request(app)
        .post('/api/v1/scenarios/simulate')
        .set('Authorization', `Bearer ${tokenCompanyA}`)
        .send({
          companyId: 'invalid-uuid-string',
        });

      expect(res.statusCode).toBe(400);
      expect(res.body.success).toBe(false);
    });

    it('returns 404 when scenarioId does not exist', async () => {
      prisma.scenario.findUnique.mockResolvedValueOnce(null);

      const res = await request(app)
        .post('/api/v1/scenarios/simulate')
        .set('Authorization', `Bearer ${tokenCompanyA}`)
        .send({
          scenarioId: scenarioAId,
        });

      expect(res.statusCode).toBe(404);
      expect(res.body.message).toMatch(/Scenario not found/i);
    });

    it('returns 400 on invalid company/scenario association', async () => {
      // Scenario belongs to company B, but company A was specified
      prisma.scenario.findUnique.mockResolvedValueOnce({
        id: scenarioAId,
        companyId: companyBId,
        name: 'Company B Scenario',
      });

      const res = await request(app)
        .post('/api/v1/scenarios/simulate')
        .set('Authorization', `Bearer ${tokenCompanyA}`)
        .send({
          companyId: companyAId,
          scenarioId: scenarioAId,
        });

      expect(res.statusCode).toBe(400);
      expect(res.body.message).toMatch(/Invalid company\/scenario association/i);
    });

    it('returns 404 when company does not exist during simulation', async () => {
      prisma.company.findUnique.mockResolvedValueOnce(null);

      const res = await request(app)
        .post('/api/v1/scenarios/simulate')
        .set('Authorization', `Bearer ${tokenCompanyA}`)
        .send({ companyId: companyAId });

      expect(res.statusCode).toBe(404);
      expect(res.body.message).toMatch(/Company not found/i);
    });

    // =======================================================================
    // Zero & Negative Burn Handling
    // =======================================================================
    describe('Zero or negative burn handling', () => {
      it('handles zero burn rate (break-even) safely with infinite runway', async () => {
        // Base burn = 10,000, additionalRevenue = 10,000 -> simulatedBurn = 0
        mockBaselineData(100000, 5000, 5000);

        const res = await request(app)
          .post('/api/v1/scenarios/simulate')
          .set('Authorization', `Bearer ${tokenCompanyA}`)
          .send({
            companyId: companyAId,
            additionalRevenue: 10000,
          });

        expect(res.statusCode).toBe(200);
        expect(res.body.data.simulated.burn).toBe(0);
        // In JSON, Infinity serializes to null
        expect(res.body.data.simulated.runway).toBeNull();
      });

      it('handles negative burn rate (profitable) safely with infinite runway', async () => {
        // Base burn = 10,000, additionalRevenue = 25,000 -> simulatedBurn = -15,000
        mockBaselineData(100000, 5000, 5000);

        const res = await request(app)
          .post('/api/v1/scenarios/simulate')
          .set('Authorization', `Bearer ${tokenCompanyA}`)
          .send({
            companyId: companyAId,
            additionalRevenue: 25000,
          });

        expect(res.statusCode).toBe(200);
        expect(res.body.data.simulated.burn).toBe(-15000);
        // In JSON, Infinity serializes to null
        expect(res.body.data.simulated.runway).toBeNull();
      });

      it('handles depleted cash (<= 0) with zero runway', async () => {
        // Cash = -10,000, Burn = 20,000
        mockBaselineData(-10000, 10000, 10000);

        const res = await request(app)
          .post('/api/v1/scenarios/simulate')
          .set('Authorization', `Bearer ${tokenCompanyA}`)
          .send({
            companyId: companyAId,
          });

        expect(res.statusCode).toBe(200);
        expect(res.body.data.simulated.cash).toBe(-10000);
        expect(res.body.data.simulated.runway).toBe(0);
      });

      it('handles depleted cash (<= 0) with negative burn as zero runway', async () => {
        // Cash = -10,000, Burn = -5,000
        mockBaselineData(-10000, 5000, 5000);

        const res = await request(app)
          .post('/api/v1/scenarios/simulate')
          .set('Authorization', `Bearer ${tokenCompanyA}`)
          .send({
            companyId: companyAId,
            additionalRevenue: 15000,
          });

        expect(res.statusCode).toBe(200);
        expect(res.body.data.simulated.cash).toBe(-10000);
        expect(res.body.data.simulated.burn).toBe(-5000);
        expect(res.body.data.simulated.runway).toBe(0);
      });
    });
  });
});
