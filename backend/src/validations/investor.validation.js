import { z } from 'zod';

export const createInvestorSchema = z.object({
  // TODO: Add full validation fields
  companyId: z.string().uuid().optional(),
});
