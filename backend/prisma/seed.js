// prisma/seed.js
// RunwayIQ Database Seeder
// Run with: node prisma/seed.js

const { PrismaClient, UserRole, StartupStage, EmploymentStatus,
  ExpenseCategory, ExpenseRecurrence, FundingRoundType,
  AssetType, Currency } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting RunwayIQ database seed...\n');

  // ── 1. Company ────────────────────────────────────────────────────────────
  const company = await prisma.company.create({
    data: {
      name: 'Acme Corp',
      legalName: 'Acme Corporation Pvt. Ltd.',
      industry: 'FinTech',
      website: 'https://acmecorp.io',
      country: 'India',
      currency: Currency.USD,
      stage: StartupStage.SEED,
      foundedAt: new Date('2022-06-01'),
    },
  });
  console.log(`✅ Company created: ${company.name} (${company.id})`);

  // ── 2. Founder (User) ─────────────────────────────────────────────────────
  const passwordHash = await bcrypt.hash('founder@123', 10);
  const founder = await prisma.user.create({
    data: {
      companyId: company.id,
      email: 'founder@acmecorp.io',
      passwordHash,
      firstName: 'Arjun',
      lastName: 'Sharma',
      role: UserRole.FOUNDER,
      isActive: true,
    },
  });
  console.log(`✅ Founder created: ${founder.firstName} ${founder.lastName} (${founder.email})`);

  // ── 3. Departments ────────────────────────────────────────────────────────
  const engineeringDept = await prisma.department.create({
    data: { companyId: company.id, name: 'Engineering', headCount: 5 },
  });
  const marketingDept = await prisma.department.create({
    data: { companyId: company.id, name: 'Marketing', headCount: 2 },
  });
  const hrDept = await prisma.department.create({
    data: { companyId: company.id, name: 'Operations', headCount: 3 },
  });
  console.log(`✅ Departments created: Engineering, Marketing, Operations`);

  // ── 4. Investors ──────────────────────────────────────────────────────────
  const investorA = await prisma.investor.create({
    data: {
      companyId: company.id,
      name: 'Riya Kapoor',
      firmName: 'Sequoia Surge',
      email: 'riya.kapoor@sequoia.com',
    },
  });
  const investorB = await prisma.investor.create({
    data: {
      companyId: company.id,
      name: 'Sam Altman',
      firmName: 'Y Combinator',
      email: 'sam@ycombinator.com',
    },
  });
  console.log(`✅ Investors created: ${investorA.name} (${investorA.firmName}), ${investorB.name} (${investorB.firmName})`);

  // ── 5. Employees ──────────────────────────────────────────────────────────
  await prisma.employee.create({
    data: {
      companyId: company.id,
      departmentId: engineeringDept.id,
      firstName: 'Sarah',
      lastName: 'Jenkins',
      email: 'sarah.jenkins@acmecorp.io',
      role: 'Chief Technology Officer',
      annualSalary: 120000,
      currency: Currency.USD,
      status: EmploymentStatus.ACTIVE,
      joinedAt: new Date('2022-07-15'),
    },
  });
  await prisma.employee.create({
    data: {
      companyId: company.id,
      departmentId: engineeringDept.id,
      firstName: 'David',
      lastName: 'Chen',
      email: 'david.chen@acmecorp.io',
      role: 'Senior Software Engineer',
      annualSalary: 95000,
      currency: Currency.USD,
      status: EmploymentStatus.ACTIVE,
      joinedAt: new Date('2022-09-01'),
    },
  });
  await prisma.employee.create({
    data: {
      companyId: company.id,
      departmentId: marketingDept.id,
      firstName: 'Elena',
      lastName: 'Rodriguez',
      email: 'elena.rodriguez@acmecorp.io',
      role: 'Marketing Lead',
      annualSalary: 85000,
      currency: Currency.USD,
      status: EmploymentStatus.ACTIVE,
      joinedAt: new Date('2023-01-10'),
    },
  });
  console.log(`✅ Employees created: Sarah Jenkins, David Chen, Elena Rodriguez`);

  // ── 6. Funding Round ──────────────────────────────────────────────────────
  const fundingRound = await prisma.fundingRound.create({
    data: {
      companyId: company.id,
      investorId: investorA.id,
      roundType: FundingRoundType.SEED,
      amountRaised: 2000000,
      currency: Currency.USD,
      equityPercent: 0.1333,
      preMoneyVal: 13000000,
      postMoneyVal: 15000000,
      closedAt: new Date('2024-01-15'),
      notes: 'Seed round led by Sequoia Surge. Used for product development and team expansion.',
    },
  });
  console.log(`✅ Funding round created: $2,000,000 (${fundingRound.roundType})`);

  // ── 7. Expenses ───────────────────────────────────────────────────────────
  const expensesData = [
    {
      title: 'AWS Cloud Infrastructure',
      description: 'Monthly AWS EC2, RDS, S3, and CloudFront charges.',
      category: ExpenseCategory.CLOUD,
      amount: 12500,
      recurrence: ExpenseRecurrence.MONTHLY,
      expenseDate: new Date('2024-10-01'),
      vendor: 'Amazon Web Services',
      departmentId: engineeringDept.id,
      isPaid: true,
    },
    {
      title: 'Meta & Google Performance Ads',
      description: 'Paid acquisition campaigns for Q4 growth targets.',
      category: ExpenseCategory.MARKETING,
      amount: 8200,
      recurrence: ExpenseRecurrence.MONTHLY,
      expenseDate: new Date('2024-10-01'),
      vendor: 'Meta Ads / Google Ads',
      departmentId: marketingDept.id,
      isPaid: true,
    },
    {
      title: 'WeWork Office Space',
      description: '10-desk private office in Bangalore.',
      category: ExpenseCategory.OFFICE_RENT,
      amount: 5000,
      recurrence: ExpenseRecurrence.MONTHLY,
      expenseDate: new Date('2024-10-01'),
      vendor: 'WeWork',
      departmentId: hrDept.id,
      isPaid: true,
    },
    {
      title: 'Software Licenses',
      description: 'GitHub Teams, Linear, Figma, Notion subscriptions.',
      category: ExpenseCategory.SOFTWARE,
      amount: 1800,
      recurrence: ExpenseRecurrence.MONTHLY,
      expenseDate: new Date('2024-10-01'),
      vendor: 'Various SaaS Vendors',
      departmentId: engineeringDept.id,
      isPaid: true,
    },
    {
      title: 'Legal & Compliance',
      description: 'Company secretary, ROC filings, contract review.',
      category: ExpenseCategory.LEGAL,
      amount: 2500,
      recurrence: ExpenseRecurrence.QUARTERLY,
      expenseDate: new Date('2024-10-05'),
      vendor: 'Trilegal LLP',
      departmentId: null,
      isPaid: false,
    },
  ];

  for (const expense of expensesData) {
    await prisma.expense.create({
      data: { companyId: company.id, ...expense },
    });
  }
  console.log(`✅ Expenses created: 5 expense records seeded`);

  // ── 8. Treasury Investments ───────────────────────────────────────────────
  await prisma.treasuryInvestment.create({
    data: {
      companyId: company.id,
      assetType: AssetType.FIXED_DEPOSIT,
      name: 'HDFC Bank Fixed Deposit',
      totalInvested: 500000,
      currentValue: 526250,
      currency: Currency.USD,
      investmentDate: new Date('2024-01-20'),
      maturityDate: new Date('2025-01-20'),
      interestRate: 0.0725,
      notes: '12-month FD at 7.25% per annum.',
    },
  });
  await prisma.treasuryInvestment.create({
    data: {
      companyId: company.id,
      assetType: AssetType.ETF,
      name: 'Nifty 50 Index ETF',
      ticker: 'NIFTYBEES',
      units: 2500,
      purchasePrice: 220,
      currentPrice: 248,
      totalInvested: 550000,
      currentValue: 620000,
      currency: Currency.USD,
      investmentDate: new Date('2024-03-01'),
      notes: 'Long-term equity position in broad market ETF.',
    },
  });
  console.log(`✅ Treasury investments created: Fixed Deposit, Nifty 50 ETF`);

  // ── 9. Scenario ───────────────────────────────────────────────────────────
  await prisma.scenario.create({
    data: {
      companyId: company.id,
      name: 'Hire 2 Senior Engineers',
      description: 'Simulates the impact of adding 2 senior engineers at $95k each annually.',
      baseCash: 1200000,
      baseMonthlyBurn: 85000,
      baseMonthlyRevenue: 14000,
      baseRunwayMonths: 14.0,
      additionalBurn: 15833,
      additionalRevenue: 0,
      additionalCash: 0,
      simulatedRunway: 11.5,
      currency: Currency.USD,
    },
  });
  console.log(`✅ Scenario created: "Hire 2 Senior Engineers"`);

  console.log('\n🎉 Seed completed successfully!');
  console.log(`   Company: ${company.name} | ID: ${company.id}`);
}

main()
  .catch((e) => {
    console.error('❌ Seed failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
