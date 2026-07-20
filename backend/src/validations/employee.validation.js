import { z } from 'zod';

export const createEmployeeSchema = z.object({
  // TODO: Add full validation fields
  companyId: z.string().uuid().optional(),
});
