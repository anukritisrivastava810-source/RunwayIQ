import { z } from 'zod';

export const createTreasurySchema = z.object({
  companyId: z.string().min(1, 'Company ID is required'),
  assetType: z.enum(['STOCK', 'ETF', 'MUTUAL_FUND', 'BOND', 'CRYPTO', 'CASH', 'FIXED_DEPOSIT']),
  name: z.string().min(1, 'Investment name is required'),
  ticker: z.string().optional().nullable(),
  units: z.coerce.number().positive('Units must be greater than 0').optional().nullable(),
  purchasePrice: z.coerce.number().min(0, 'Purchase price must be non-negative'),
  totalInvested: z.coerce.number().positive('Total invested must be greater than 0'),
  currentPrice: z.coerce.number().optional().nullable(),
  currentValue: z.coerce.number().optional().nullable(),
  currency: z.enum(['USD', 'INR', 'EUR', 'GBP', 'SGD', 'AED']).default('USD'),
  investmentDate: z.coerce.date(),
  maturityDate: z.coerce.date().optional().nullable(),
  interestRate: z.coerce.number().min(0).max(1).optional().nullable(),
  notes: z.string().optional().nullable(),
}).refine(data => {
  const marketTypes = ['STOCK', 'ETF', 'MUTUAL_FUND', 'CRYPTO'];
  if (marketTypes.includes(data.assetType)) {
    return Boolean(data.ticker && data.ticker.trim()) && data.units != null && data.units > 0;
  }
  return true;
}, {
  message: 'Market-priced investments (STOCK, ETF, MUTUAL_FUND, CRYPTO) require a valid ticker and positive quantity/units',
  path: ['ticker'],
});

export const updateTreasurySchema = z.object({
  companyId: z.string().min(1).optional(),
  assetType: z.enum(['STOCK', 'ETF', 'MUTUAL_FUND', 'BOND', 'CRYPTO', 'CASH', 'FIXED_DEPOSIT']).optional(),
  name: z.string().min(1).optional(),
  ticker: z.string().optional().nullable(),
  units: z.coerce.number().positive('Units must be greater than 0').optional().nullable(),
  purchasePrice: z.coerce.number().min(0).optional(),
  totalInvested: z.coerce.number().positive().optional(),
  currentPrice: z.coerce.number().optional().nullable(),
  currentValue: z.coerce.number().optional().nullable(),
  currency: z.enum(['USD', 'INR', 'EUR', 'GBP', 'SGD', 'AED']).optional(),
  investmentDate: z.coerce.date().optional(),
  maturityDate: z.coerce.date().optional().nullable(),
  interestRate: z.coerce.number().min(0).max(1).optional().nullable(),
  notes: z.string().optional().nullable(),
});
