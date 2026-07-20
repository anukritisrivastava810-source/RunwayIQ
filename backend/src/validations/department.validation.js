import { z } from 'zod';

export const createDepartmentSchema = z.object({
  // TODO: Add full validation fields
  companyId: z.string().uuid().optional(),
});
