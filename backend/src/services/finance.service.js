import prisma from '../config/prisma.js';
import { AnalyticsService } from './analytics.service.js';

const analyticsService = new AnalyticsService();

/**
 * FinanceService handles report generation and transactional operations.
 */
export class FinanceService {

  // ==========================================
  // FINANCIAL REPORTS
  // ==========================================

  /**
   * Generates a comprehensive monthly financial summary
   * // TODO: Implement Redis caching for expensive aggregations
   */
  async getMonthlySummary(companyId) {
    const expenses = await analyticsService.getExpensesData(companyId);
    const payroll = await analyticsService.getMonthlyPayroll(companyId);
    const burnRate = await analyticsService.getMonthlyBurnRate(companyId);
    const runway = await analyticsService.getRunwayMonths(companyId);
    const cash = await analyticsService.getCurrentCash(companyId);

    return {
      period: 'Monthly',
      date: new Date().toISOString(),
      cashRemaining: cash,
      monthlyBurnRate: burnRate,
      runwayMonths: runway,
      totalExpenses: expenses.currentMonthExpenses,
      totalPayroll: payroll
    };
  }

  async getQuarterlySummary(companyId) {
    // Similar to monthly, but grouped by quarter.
    // For simplicity, we just aggregate all for now and label it Quarterly.
    const summary = await this.getMonthlySummary(companyId);
    summary.period = 'Quarterly';
    summary.totalExpenses *= 3;
    summary.totalPayroll *= 3;
    return summary;
  }

  async getYearlySummary(companyId) {
    const summary = await this.getMonthlySummary(companyId);
    summary.period = 'Yearly';
    summary.totalExpenses *= 12;
    summary.totalPayroll *= 12;
    return summary;
  }

  async getFundingReport(companyId) {
    return await analyticsService.getFundingStats(companyId);
  }

  async getExpenseReport(companyId) {
    const stats = await analyticsService.getExpensesData(companyId);
    const byCategory = await analyticsService.getExpensesByCategory(companyId);
    const byType = await analyticsService.getExpensesByType(companyId);
    return { stats, byCategory, byType };
  }

  async getPayrollReport(companyId) {
    const stats = await analyticsService.getPayrollStats(companyId);
    const byDept = await analyticsService.getPayrollByDepartment(companyId);
    return { stats, byDepartment: byDept };
  }

  async getTreasuryReport(companyId) {
    // Basic aggregation for treasury
    const stats = await prisma.treasuryInvestment.aggregate({
      where: { companyId },
      _sum: { totalInvested: true, currentValue: true }
    });
    return {
      totalInvested: Number(stats._sum.totalInvested || 0),
      currentValue: Number(stats._sum.currentValue || 0)
    };
  }

  async getDepartmentReport(companyId) {
    const depts = await prisma.department.findMany({
      where: { companyId },
      include: { 
        _count: { select: { employees: true, expenses: true } }
      }
    });
    return depts;
  }

  // ==========================================
  // TRANSACTIONS
  // ==========================================

  /**
   * Example of using Prisma Transactions for multiple writes
   * to ensure consistency across the database.
   */
  async addEmployeeWithDepartmentUpdate(data) {
    return await prisma.$transaction(async (tx) => {
      const employee = await tx.employee.create({ data });
      
      // Update department headcount
      await tx.department.update({
        where: { id: employee.departmentId },
        data: { headCount: { increment: 1 } }
      });

      return employee;
    });
  }
}
