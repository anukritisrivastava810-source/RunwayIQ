import { z } from 'zod';

export const createTreasurySchema = z.object({
  // TODO: Add full validation fields
  companyId: z.string().uuid().optional(),
});
