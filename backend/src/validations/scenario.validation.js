import { z } from 'zod';

export const createScenarioSchema = z.object({
  // TODO: Add full validation fields
  companyId: z.string().uuid().optional(),
});
