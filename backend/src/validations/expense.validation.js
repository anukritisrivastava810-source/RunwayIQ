import { z } from 'zod';

export const createExpenseSchema = z.object({
  // TODO: Add full validation fields
  companyId: z.string().uuid().optional(),
});
