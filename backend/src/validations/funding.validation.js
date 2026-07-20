import { z } from 'zod';

export const createFundingSchema = z.object({
  // TODO: Add full validation fields
  companyId: z.string().uuid().optional(),
});
