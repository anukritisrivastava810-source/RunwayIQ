import { z } from 'zod';
import { isValidUUID } from '../utils/validators.js';

export const simulateScenarioSchema = z.object({
  companyId: z.string().refine(isValidUUID, { message: 'Invalid company ID format' }).optional(),
  scenarioId: z.string().refine(isValidUUID, { message: 'Invalid scenario ID format' }).optional(),
  additionalBurn: z.union([z.number(), z.string()]).optional().refine(val => {
    if (val === undefined || val === null) return true;
    const num = Number(val);
    return !isNaN(num) && isFinite(num);
  }, { message: 'additionalBurn must be a valid number' }),
  additionalRevenue: z.union([z.number(), z.string()]).optional().refine(val => {
    if (val === undefined || val === null) return true;
    const num = Number(val);
    return !isNaN(num) && isFinite(num);
  }, { message: 'additionalRevenue must be a valid number' }),
  additionalCash: z.union([z.number(), z.string()]).optional().refine(val => {
    if (val === undefined || val === null) return true;
    const num = Number(val);
    return !isNaN(num) && isFinite(num);
  }, { message: 'additionalCash must be a valid number' }),
}).refine(data => Boolean(data.companyId || data.scenarioId), {
  message: 'Either companyId or scenarioId is required',
  path: ['companyId'],
});

export const createScenarioSchema = z.object({
  companyId: z.string().refine(isValidUUID, { message: 'Invalid company ID format' }).optional(),
  name: z.string().min(1, 'Name is required'),
  description: z.string().optional(),
  baseCash: z.union([z.number(), z.string()]).optional(),
  baseMonthlyBurn: z.union([z.number(), z.string()]).optional(),
  baseMonthlyRevenue: z.union([z.number(), z.string()]).optional(),
  baseRunwayMonths: z.union([z.number(), z.string()]).optional(),
  additionalBurn: z.union([z.number(), z.string()]).optional(),
  additionalRevenue: z.union([z.number(), z.string()]).optional(),
  additionalCash: z.union([z.number(), z.string()]).optional(),
  simulatedRunway: z.union([z.number(), z.string()]).optional(),
  currency: z.enum(['USD', 'INR', 'EUR', 'GBP', 'SGD', 'AED']).optional(),
  isActive: z.boolean().optional(),
});
