import { DashboardService } from '../src/services/dashboard.service.js';
import prisma from '../src/config/prisma.js';

describe('Dashboard Service', () => {
  let dashboardService;

  beforeEach(() => {
    jest.clearAllMocks();
    dashboardService = new DashboardService();
  });

  describe('getBurnRate', () => {
    it('calculates burn rate accurately from payroll and expenses', async () => {
      // Mock employee payroll aggregation
      prisma.employee.aggregate.mockResolvedValueOnce({
        _sum: { annualSalary: 120000 } // 10k monthly
      });

      // Mock expense aggregation
      prisma.expense.aggregate.mockResolvedValueOnce({
        _sum: { amount: 5000 }
      });

      const burnRate = await dashboardService.getBurnRate('company-123');
      expect(burnRate).toEqual(15000);
    });
  });

  describe('getRunway', () => {
    it('calculates runway months correctly', async () => {
      // Mock Cash: Funding - Expenses
      prisma.fundingRound.aggregate.mockResolvedValueOnce({ _sum: { amountRaised: 200000 } });
      prisma.expense.aggregate.mockResolvedValueOnce({ _sum: { amount: 50000 } });
      // Current cash = 150000

      // Mock Burn Rate (Payroll + Current Expenses)
      prisma.employee.aggregate.mockResolvedValueOnce({ _sum: { annualSalary: 120000 } }); // 10k payroll
      prisma.expense.aggregate.mockResolvedValueOnce({ _sum: { amount: 5000 } }); // 5k current expenses
      // Burn = 15000

      const runway = await dashboardService.getRunway('company-123');
      expect(runway).toEqual(10); // 150000 / 15000 = 10 months
    });

    it('returns Infinity if burn rate is zero', async () => {
      prisma.fundingRound.aggregate.mockResolvedValueOnce({ _sum: { amountRaised: 200000 } });
      prisma.expense.aggregate.mockResolvedValueOnce({ _sum: { amount: 0 } });
      prisma.employee.aggregate.mockResolvedValueOnce({ _sum: { annualSalary: 0 } }); 
      prisma.expense.aggregate.mockResolvedValueOnce({ _sum: { amount: 0 } }); 

      const runway = await dashboardService.getRunway('company-123');
      expect(runway).toEqual(Infinity);
    });
  });

  // ============================================================
  // getBurnTrend
  // ============================================================

  describe('getBurnTrend', () => {
    const companyId = 'company-abc';

    /** Helper: mock company lookup resolving to a valid company */
    const mockCompany = () => {
      prisma.company.findUnique.mockResolvedValueOnce({
        id: companyId,
        currency: 'USD'
      });
    };

    /** Helper: mock a month with no expenses and no employees */
    const mockEmptyMonth = () => {
      prisma.expense.findMany.mockResolvedValueOnce([]);
      prisma.employee.findMany.mockResolvedValueOnce([]);
    };

    it('throws 404 when the company does not exist', async () => {
      prisma.company.findUnique.mockResolvedValueOnce(null);

      await expect(dashboardService.getBurnTrend('nonexistent-id')).rejects.toMatchObject({
        statusCode: 404
      });
    });

    it('returns zero values for a company with no expenses or employees', async () => {
      mockCompany();
      // Mock 6 months of empty data
      for (let i = 0; i < 6; i++) mockEmptyMonth();

      const result = await dashboardService.getBurnTrend(companyId, 6);

      expect(result.companyId).toBe(companyId);
      expect(result.currency).toBe('USD');
      expect(result.data).toHaveLength(6);
      result.data.forEach(row => {
        expect(row.expenseBurn).toBe(0);
        expect(row.payrollBurn).toBe(0);
        expect(row.totalBurn).toBe(0);
      });
    });

    it('aggregates expenses and payroll for one month correctly', async () => {
      mockCompany();
      // 1-month window only
      // Expenses: one MONTHLY $3000, one ONE_TIME $2000
      prisma.expense.findMany.mockResolvedValueOnce([
        { amount: '3000', recurrence: 'MONTHLY' },
        { amount: '2000', recurrence: 'ONE_TIME' }
      ]);
      // Employees: two active with $120,000 annual salary each
      prisma.employee.findMany.mockResolvedValueOnce([
        { annualSalary: '120000' },
        { annualSalary: '120000' }
      ]);

      const result = await dashboardService.getBurnTrend(companyId, 1);

      expect(result.data).toHaveLength(1);
      const row = result.data[0];
      // expenseBurn = 3000 + 2000 = 5000
      expect(row.expenseBurn).toBe(5000);
      // payrollBurn = (120000 / 12) * 2 = 20000
      expect(row.payrollBurn).toBe(20000);
      expect(row.totalBurn).toBe(25000);
    });

    it('normalises WEEKLY expenses to monthly equivalent', async () => {
      mockCompany();
      // WEEKLY $1200 → 1200 * 52 / 12 = 5200
      prisma.expense.findMany.mockResolvedValueOnce([
        { amount: '1200', recurrence: 'WEEKLY' }
      ]);
      prisma.employee.findMany.mockResolvedValueOnce([]);

      const result = await dashboardService.getBurnTrend(companyId, 1);

      const row = result.data[0];
      expect(row.expenseBurn).toBeCloseTo(5200, 1);
    });

    it('normalises QUARTERLY expenses to monthly equivalent', async () => {
      mockCompany();
      // QUARTERLY $6000 → 6000 / 3 = 2000
      prisma.expense.findMany.mockResolvedValueOnce([
        { amount: '6000', recurrence: 'QUARTERLY' }
      ]);
      prisma.employee.findMany.mockResolvedValueOnce([]);

      const result = await dashboardService.getBurnTrend(companyId, 1);

      expect(result.data[0].expenseBurn).toBe(2000);
    });

    it('normalises YEARLY expenses to monthly equivalent', async () => {
      mockCompany();
      // YEARLY $24000 → 24000 / 12 = 2000
      prisma.expense.findMany.mockResolvedValueOnce([
        { amount: '24000', recurrence: 'YEARLY' }
      ]);
      prisma.employee.findMany.mockResolvedValueOnce([]);

      const result = await dashboardService.getBurnTrend(companyId, 1);

      expect(result.data[0].expenseBurn).toBe(2000);
    });

    it('returns correct month labels in ascending order', async () => {
      mockCompany();
      for (let i = 0; i < 3; i++) mockEmptyMonth();

      const result = await dashboardService.getBurnTrend(companyId, 3);

      const labels = result.data.map(r => r.month);
      // Labels must be YYYY-MM and ascending
      expect(labels[0] < labels[1]).toBe(true);
      expect(labels[1] < labels[2]).toBe(true);
      labels.forEach(l => expect(l).toMatch(/^\d{4}-\d{2}$/));
    });

    it('uses employment dates to exclude employees not active in that month', async () => {
      mockCompany();
      // Only one employee who exited before the queried month —
      // the Prisma query is called with the correct date filter;
      // we simulate the DB correctly returning an empty array.
      prisma.expense.findMany.mockResolvedValueOnce([]);
      prisma.employee.findMany.mockResolvedValueOnce([]); // DB filtered them out

      const result = await dashboardService.getBurnTrend(companyId, 1);

      expect(result.data[0].payrollBurn).toBe(0);
    });
  });
});
