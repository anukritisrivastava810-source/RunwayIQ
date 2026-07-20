import { z } from 'zod';

export const createCompanySchema = z.object({
  // TODO: Add full validation fields
  companyId: z.string().uuid().optional(),
});
