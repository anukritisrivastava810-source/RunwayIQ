-- CreateEnum
CREATE TYPE "UserRole" AS ENUM ('FOUNDER', 'FINANCE_MANAGER', 'HR', 'INVESTOR');

-- CreateEnum
CREATE TYPE "StartupStage" AS ENUM ('IDEA', 'PRE_SEED', 'SEED', 'SERIES_A', 'SERIES_B', 'SERIES_C', 'GROWTH', 'IPO');

-- CreateEnum
CREATE TYPE "EmploymentStatus" AS ENUM ('ACTIVE', 'INACTIVE', 'NOTICE', 'RESIGNED');

-- CreateEnum
CREATE TYPE "ExpenseCategory" AS ENUM ('PAYROLL', 'CLOUD', 'MARKETING', 'OFFICE_RENT', 'UTILITIES', 'LEGAL', 'SOFTWARE', 'TRAVEL', 'HARDWARE', 'OTHER');

-- CreateEnum
CREATE TYPE "ExpenseRecurrence" AS ENUM ('ONE_TIME', 'WEEKLY', 'MONTHLY', 'QUARTERLY', 'YEARLY');

-- CreateEnum
CREATE TYPE "FundingRoundType" AS ENUM ('PRE_SEED', 'SEED', 'SERIES_A', 'SERIES_B', 'SERIES_C', 'BRIDGE', 'DEBT', 'GRANT', 'IPO');

-- CreateEnum
CREATE TYPE "AssetType" AS ENUM ('STOCK', 'ETF', 'MUTUAL_FUND', 'BOND', 'CRYPTO', 'CASH', 'FIXED_DEPOSIT');

-- CreateEnum
CREATE TYPE "Currency" AS ENUM ('USD', 'INR', 'EUR', 'GBP', 'SGD', 'AED');

-- CreateTable
CREATE TABLE "companies" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "legalName" TEXT,
    "industry" TEXT,
    "website" TEXT,
    "logoUrl" TEXT,
    "country" TEXT,
    "currency" "Currency" NOT NULL DEFAULT 'USD',
    "stage" "StartupStage" NOT NULL DEFAULT 'PRE_SEED',
    "foundedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "companies_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "users" (
    "id" TEXT NOT NULL,
    "companyId" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "passwordHash" TEXT NOT NULL,
    "firstName" TEXT NOT NULL,
    "lastName" TEXT NOT NULL,
    "role" "UserRole" NOT NULL DEFAULT 'FOUNDER',
    "avatarUrl" TEXT,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "lastLoginAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "departments" (
    "id" TEXT NOT NULL,
    "companyId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "headCount" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "departments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "employees" (
    "id" TEXT NOT NULL,
    "companyId" TEXT NOT NULL,
    "departmentId" TEXT NOT NULL,
    "firstName" TEXT NOT NULL,
    "lastName" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "role" TEXT NOT NULL,
    "annualSalary" DECIMAL(15,2) NOT NULL,
    "currency" "Currency" NOT NULL DEFAULT 'USD',
    "status" "EmploymentStatus" NOT NULL DEFAULT 'ACTIVE',
    "joinedAt" TIMESTAMP(3) NOT NULL,
    "exitedAt" TIMESTAMP(3),
    "avatarUrl" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "employees_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "investors" (
    "id" TEXT NOT NULL,
    "companyId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "firmName" TEXT,
    "email" TEXT,
    "logoUrl" TEXT,
    "linkedinUrl" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "investors_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "funding_rounds" (
    "id" TEXT NOT NULL,
    "companyId" TEXT NOT NULL,
    "investorId" TEXT NOT NULL,
    "roundType" "FundingRoundType" NOT NULL,
    "amountRaised" DECIMAL(18,2) NOT NULL,
    "currency" "Currency" NOT NULL DEFAULT 'USD',
    "equityPercent" DECIMAL(5,4),
    "preMoneyVal" DECIMAL(18,2),
    "postMoneyVal" DECIMAL(18,2),
    "closedAt" TIMESTAMP(3) NOT NULL,
    "notes" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "funding_rounds_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "expenses" (
    "id" TEXT NOT NULL,
    "companyId" TEXT NOT NULL,
    "departmentId" TEXT,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "category" "ExpenseCategory" NOT NULL DEFAULT 'OTHER',
    "amount" DECIMAL(15,2) NOT NULL,
    "currency" "Currency" NOT NULL DEFAULT 'USD',
    "recurrence" "ExpenseRecurrence" NOT NULL DEFAULT 'ONE_TIME',
    "expenseDate" TIMESTAMP(3) NOT NULL,
    "receiptUrl" TEXT,
    "vendor" TEXT,
    "isPaid" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "expenses_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "treasury_investments" (
    "id" TEXT NOT NULL,
    "companyId" TEXT NOT NULL,
    "assetType" "AssetType" NOT NULL,
    "name" TEXT NOT NULL,
    "ticker" TEXT,
    "units" DECIMAL(18,8),
    "purchasePrice" DECIMAL(15,2) NOT NULL,
    "currentPrice" DECIMAL(15,2),
    "totalInvested" DECIMAL(15,2) NOT NULL,
    "currentValue" DECIMAL(15,2),
    "currency" "Currency" NOT NULL DEFAULT 'USD',
    "investmentDate" TIMESTAMP(3) NOT NULL,
    "maturityDate" TIMESTAMP(3),
    "interestRate" DECIMAL(5,4),
    "notes" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "treasury_investments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "scenarios" (
    "id" TEXT NOT NULL,
    "companyId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "baseCash" DECIMAL(15,2) NOT NULL,
    "baseMonthlyBurn" DECIMAL(15,2) NOT NULL,
    "baseMonthlyRevenue" DECIMAL(15,2) NOT NULL,
    "baseRunwayMonths" DECIMAL(5,2) NOT NULL,
    "additionalBurn" DECIMAL(15,2) NOT NULL DEFAULT 0,
    "additionalRevenue" DECIMAL(15,2) NOT NULL DEFAULT 0,
    "additionalCash" DECIMAL(15,2) NOT NULL DEFAULT 0,
    "simulatedRunway" DECIMAL(5,2),
    "currency" "Currency" NOT NULL DEFAULT 'USD',
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "scenarios_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "companies_name_idx" ON "companies"("name");

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE INDEX "users_companyId_idx" ON "users"("companyId");

-- CreateIndex
CREATE INDEX "users_email_idx" ON "users"("email");

-- CreateIndex
CREATE INDEX "departments_companyId_idx" ON "departments"("companyId");

-- CreateIndex
CREATE UNIQUE INDEX "departments_companyId_name_key" ON "departments"("companyId", "name");

-- CreateIndex
CREATE UNIQUE INDEX "employees_email_key" ON "employees"("email");

-- CreateIndex
CREATE INDEX "employees_companyId_idx" ON "employees"("companyId");

-- CreateIndex
CREATE INDEX "employees_email_idx" ON "employees"("email");

-- CreateIndex
CREATE INDEX "investors_companyId_idx" ON "investors"("companyId");

-- CreateIndex
CREATE INDEX "funding_rounds_companyId_idx" ON "funding_rounds"("companyId");

-- CreateIndex
CREATE INDEX "funding_rounds_closedAt_idx" ON "funding_rounds"("closedAt");

-- CreateIndex
CREATE INDEX "expenses_companyId_idx" ON "expenses"("companyId");

-- CreateIndex
CREATE INDEX "expenses_expenseDate_idx" ON "expenses"("expenseDate");

-- CreateIndex
CREATE INDEX "treasury_investments_companyId_idx" ON "treasury_investments"("companyId");

-- CreateIndex
CREATE INDEX "treasury_investments_investmentDate_idx" ON "treasury_investments"("investmentDate");

-- CreateIndex
CREATE INDEX "scenarios_companyId_idx" ON "scenarios"("companyId");

-- AddForeignKey
ALTER TABLE "users" ADD CONSTRAINT "users_companyId_fkey" FOREIGN KEY ("companyId") REFERENCES "companies"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "departments" ADD CONSTRAINT "departments_companyId_fkey" FOREIGN KEY ("companyId") REFERENCES "companies"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "employees" ADD CONSTRAINT "employees_companyId_fkey" FOREIGN KEY ("companyId") REFERENCES "companies"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "employees" ADD CONSTRAINT "employees_departmentId_fkey" FOREIGN KEY ("departmentId") REFERENCES "departments"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "investors" ADD CONSTRAINT "investors_companyId_fkey" FOREIGN KEY ("companyId") REFERENCES "companies"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "funding_rounds" ADD CONSTRAINT "funding_rounds_companyId_fkey" FOREIGN KEY ("companyId") REFERENCES "companies"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "funding_rounds" ADD CONSTRAINT "funding_rounds_investorId_fkey" FOREIGN KEY ("investorId") REFERENCES "investors"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "expenses" ADD CONSTRAINT "expenses_companyId_fkey" FOREIGN KEY ("companyId") REFERENCES "companies"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "expenses" ADD CONSTRAINT "expenses_departmentId_fkey" FOREIGN KEY ("departmentId") REFERENCES "departments"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "treasury_investments" ADD CONSTRAINT "treasury_investments_companyId_fkey" FOREIGN KEY ("companyId") REFERENCES "companies"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "scenarios" ADD CONSTRAINT "scenarios_companyId_fkey" FOREIGN KEY ("companyId") REFERENCES "companies"("id") ON DELETE CASCADE ON UPDATE CASCADE;
