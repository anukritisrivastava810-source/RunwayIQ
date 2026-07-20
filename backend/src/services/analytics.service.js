import prisma from '../config/prisma.js';

/**
 * AnalyticsService handles all deep data aggregations using Prisma.
 * All calculations are dynamic and real-time.
 */
export class AnalyticsService {
  
  // ==========================================
  // PAYROLL ENGINE
  // ==========================================

  /**
   * Calculates the total monthly payroll.
   * Formula: SUM(Employee.annualSalary) / 12
   */
  async getMonthlyPayroll(companyId) {
    const result = await prisma.employee.aggregate({
      where: { companyId, status: 'ACTIVE' },
      _sum: { annualSalary: true }
    });
    const annualTotal = Number(result._sum.annualSalary || 0);
    return annualTotal / 12;
  }

  /**
   * Retrieves comprehensive payroll statistics
   */
  async getPayrollStats(companyId) {
    const result = await prisma.employee.aggregate({
      where: { companyId, status: 'ACTIVE' },
      _sum: { annualSalary: true },
      _max: { annualSalary: true },
      _min: { annualSalary: true },
      _avg: { annualSalary: true },
      _count: { id: true }
    });

    const annualTotal = Number(result._sum.annualSalary || 0);
    return {
      monthlyPayroll: annualTotal / 12,
      annualPayroll: annualTotal,
      highestSalary: Number(result._max.annualSalary || 0),
      lowestSalary: Number(result._min.annualSalary || 0),
      averageSalary: Number(result._avg.annualSalary || 0),
      employeeCount: result._count.id
    };
  }

  /**
   * Groups payroll distribution by department
   */
  async getPayrollByDepartment(companyId) {
    const employees = await prisma.employee.findMany({
      where: { companyId, status: 'ACTIVE' },
      include: { department: true }
    });

    const deptMap = {};
    employees.forEach(emp => {
      const deptName = emp.department.name;
      const salary = Number(emp.annualSalary);
      if (!deptMap[deptName]) deptMap[deptName] = 0;
      deptMap[deptName] += (salary / 12);
    });

    return Object.keys(deptMap).map(name => ({
      department: name,
      monthlyPayroll: deptMap[name]
    }));
  }

  // ==========================================
  // EXPENSE ANALYTICS
  // ==========================================

  /**
   * Calculates expenses for a specific period or total
   */
  async getExpensesData(companyId) {
    const now = new Date();
    const firstDayCurrent = new Date(now.getFullYear(), now.getMonth(), 1);
    const firstDayPrev = new Date(now.getFullYear(), now.getMonth() - 1, 1);

    const [total, currentMonth, prevMonth, stats] = await Promise.all([
      prisma.expense.aggregate({ where: { companyId }, _sum: { amount: true } }),
      prisma.expense.aggregate({ where: { companyId, expenseDate: { gte: firstDayCurrent } }, _sum: { amount: true } }),
      prisma.expense.aggregate({ where: { companyId, expenseDate: { gte: firstDayPrev, lt: firstDayCurrent } }, _sum: { amount: true } }),
      prisma.expense.aggregate({
        where: { companyId },
        _avg: { amount: true },
        _max: { amount: true },
        _min: { amount: true }
      })
    ]);

    return {
      totalExpenses: Number(total._sum.amount || 0),
      currentMonthExpenses: Number(currentMonth._sum.amount || 0),
      previousMonthExpenses: Number(prevMonth._sum.amount || 0),
      averageExpense: Number(stats._avg.amount || 0),
      highestExpense: Number(stats._max.amount || 0),
      lowestExpense: Number(stats._min.amount || 0),
    };
  }

  async getExpensesByCategory(companyId) {
    const grouped = await prisma.expense.groupBy({
      by: ['category'],
      where: { companyId },
      _sum: { amount: true },
      orderBy: { _sum: { amount: 'desc' } }
    });
    return grouped.map(g => ({ category: g.category, total: Number(g._sum.amount || 0) }));
  }

  async getExpensesByType(companyId) {
    const grouped = await prisma.expense.groupBy({
      by: ['recurrence'],
      where: { companyId },
      _sum: { amount: true }
    });
    return grouped.map(g => ({ type: g.recurrence, total: Number(g._sum.amount || 0) }));
  }

  // ==========================================
  // FUNDING ANALYTICS
  // ==========================================

  async getFundingStats(companyId) {
    const stats = await prisma.fundingRound.aggregate({
      where: { companyId },
      _sum: { amountRaised: true, equityPercent: true },
      _avg: { amountRaised: true },
      _max: { amountRaised: true }
    });

    const latest = await prisma.fundingRound.findFirst({
      where: { companyId },
      orderBy: { closedAt: 'desc' }
    });

    return {
      totalFundingRaised: Number(stats._sum.amountRaised || 0),
      averageRoundSize: Number(stats._avg.amountRaised || 0),
      highestRound: Number(stats._max.amountRaised || 0),
      totalEquityDiluted: Number(stats._sum.equityPercent || 0),
      currentValuation: latest ? Number(latest.postMoneyVal || 0) : 0,
      latestFunding: latest ? Number(latest.amountRaised) : 0
    };
  }

  async getFundingByInvestor(companyId) {
    const grouped = await prisma.fundingRound.groupBy({
      by: ['investorId'],
      where: { companyId },
      _sum: { amountRaised: true }
    });
    
    // We need investor names, so we can fetch them
    const investorIds = grouped.map(g => g.investorId);
    const investors = await prisma.investor.findMany({ where: { id: { in: investorIds } } });
    const invMap = {};
    investors.forEach(inv => invMap[inv.id] = inv.name);

    return grouped.map(g => ({
      investor: invMap[g.investorId] || 'Unknown',
      total: Number(g._sum.amountRaised || 0)
    }));
  }

  // ==========================================
  // RUNWAY ENGINE
  // ==========================================

  /**
   * Calculates the monthly burn rate.
   * Formula: Monthly Payroll + Monthly Recurring Expenses
   */
  async getMonthlyBurnRate(companyId) {
    const payroll = await this.getMonthlyPayroll(companyId);
    
    const now = new Date();
    const firstDayCurrent = new Date(now.getFullYear(), now.getMonth(), 1);

    const expenses = await prisma.expense.aggregate({
      where: { 
        companyId, 
        expenseDate: { gte: firstDayCurrent }
      },
      _sum: { amount: true }
    });
    
    const monthlyExpenses = Number(expenses._sum.amount || 0);
    return payroll + monthlyExpenses;
  }

  /**
   * Calculates Cash Remaining
   * Formula: Total Funding - Total Expenses
   */
  async getCurrentCash(companyId) {
    const funding = await prisma.fundingRound.aggregate({ where: { companyId }, _sum: { amountRaised: true }});
    const expenses = await prisma.expense.aggregate({ where: { companyId }, _sum: { amount: true }});
    // This is a naive calculation for cash. In real systems, starting balance and revenue would be included.
    return Number(funding._sum.amountRaised || 0) - Number(expenses._sum.amount || 0);
  }

  /**
   * Calculates remaining runway in months
   */
  async getRunwayMonths(companyId) {
    const cash = await this.getCurrentCash(companyId);
    const burnRate = await this.getMonthlyBurnRate(companyId);

    if (burnRate <= 0) return Infinity;
    return cash / burnRate;
  }

  // ==========================================
  // SEARCH, FILTER, AND PAGINATION
  // ==========================================
  
  async searchEmployees(companyId, queryOptions) {
    const { buildPrismaQuery } = await import('../utils/queryBuilder.js');
    const query = buildPrismaQuery(queryOptions);
    query.where.companyId = companyId;
    return await prisma.employee.findMany(query);
  }

  async searchExpenses(companyId, queryOptions) {
    const { buildPrismaQuery } = await import('../utils/queryBuilder.js');
    const query = buildPrismaQuery(queryOptions);
    query.where.companyId = companyId;
    return await prisma.expense.findMany(query);
  }

  async searchFunding(companyId, queryOptions) {
    const { buildPrismaQuery } = await import('../utils/queryBuilder.js');
    const query = buildPrismaQuery(queryOptions);
    query.where.companyId = companyId;
    return await prisma.fundingRound.findMany(query);
  }

  async searchInvestors(companyId, queryOptions) {
    const { buildPrismaQuery } = await import('../utils/queryBuilder.js');
    const query = buildPrismaQuery(queryOptions);
    query.where.companyId = companyId;
    return await prisma.investor.findMany(query);
  }

  async searchTreasury(companyId, queryOptions) {
    const { buildPrismaQuery } = await import('../utils/queryBuilder.js');
    const query = buildPrismaQuery(queryOptions);
    query.where.companyId = companyId;
    return await prisma.treasuryInvestment.findMany(query);
  }

  async searchScenarios(companyId, queryOptions) {
    const { buildPrismaQuery } = await import('../utils/queryBuilder.js');
    const query = buildPrismaQuery(queryOptions);
    query.where.companyId = companyId;
    return await prisma.scenario.findMany(query);
  }
}
