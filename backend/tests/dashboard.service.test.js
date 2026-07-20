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
});
