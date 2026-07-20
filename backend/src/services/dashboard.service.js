import { AnalyticsService } from './analytics.service.js';

const analyticsService = new AnalyticsService();

export class DashboardService {
  async getDashboard(companyId) {
    const expenses = await analyticsService.getExpensesData(companyId);
    const payroll = await analyticsService.getPayrollStats(companyId);
    const funding = await analyticsService.getFundingStats(companyId);
    const burnRate = await analyticsService.getMonthlyBurnRate(companyId);
    const runway = await analyticsService.getRunwayMonths(companyId);
    const cash = await analyticsService.getCurrentCash(companyId);

    return {
      currentCash: cash,
      totalFundingRaised: funding.totalFundingRaised,
      monthlyPayroll: payroll.monthlyPayroll,
      monthlyExpenses: expenses.currentMonthExpenses,
      monthlyBurnRate: burnRate,
      remainingRunwayMonths: runway,
      totalEmployees: payroll.employeeCount,
      departmentCount: 0, // This could be fetched from Dept service
      totalInvestors: 0,  // This could be fetched from Investor service
      portfolioValue: 0,  // From Treasury
      totalEquityDiluted: funding.totalEquityDiluted,
      averageMonthlyExpense: expenses.averageExpense,
      cashRemainingAfterPayroll: cash - payroll.monthlyPayroll
    };
  }

  async getBurnRate(companyId) {
    const burnRate = await analyticsService.getMonthlyBurnRate(companyId);
    return burnRate;
  }

  async getRunway(companyId) {
    const runway = await analyticsService.getRunwayMonths(companyId);
    return runway;
  }

  async getFundingSummary(companyId) {
    return await analyticsService.getFundingStats(companyId);
  }

  // ==========================================
  // DASHBOARD CHARTS
  // ==========================================

  async getExpenseTrendChart(companyId) {
    const expenses = await analyticsService.getExpensesData(companyId); // This needs historical data
    // Return mock optimized for Flutter charts until full historical aggregation is implemented
    return [
      { month: 'Jan', value: expenses.averageExpense * 0.9 },
      { month: 'Feb', value: expenses.averageExpense * 1.1 },
      { month: 'Mar', value: expenses.currentMonthExpenses }
    ];
  }

  async getPayrollTrendChart(companyId) {
    const payroll = await analyticsService.getMonthlyPayroll(companyId);
    return [
      { month: 'Jan', value: payroll },
      { month: 'Feb', value: payroll },
      { month: 'Mar', value: payroll }
    ];
  }

  async getFundingTrendChart(companyId) {
    return await analyticsService.getFundingByInvestor(companyId);
  }

  async getRunwayProjectionChart(companyId) {
    const runway = await analyticsService.getRunwayMonths(companyId);
    const cash = await analyticsService.getCurrentCash(companyId);
    const burn = await analyticsService.getMonthlyBurnRate(companyId);
    
    const projection = [];
    let currentCash = cash;
    for (let i = 0; i <= Math.min(runway, 12); i++) {
      projection.push({ month: `Month ${i}`, cash: currentCash });
      currentCash -= burn;
    }
    return projection;
  }

  async getDepartmentSpendingChart(companyId) {
    return await analyticsService.getPayrollByDepartment(companyId);
  }

  async getTreasuryAllocationChart(companyId) {
    const treasury = await import('./treasury.service.js').then(m => new m.TreasuryService());
    const summary = await treasury.getPortfolioSummary(companyId);
    return summary.investmentAllocation;
  }
}
