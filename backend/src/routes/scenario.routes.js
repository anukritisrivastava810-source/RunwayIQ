import { Router } from 'express';
import {
  getScenarios,
  getScenarioById,
  getScenariosByCompanyId,
  createScenario,
  updateScenario,
  deleteScenario,
  simulateScenario
} from '../controllers/scenario.controller.js';
import { authenticateUser } from '../middleware/auth.middleware.js';
import { validateRequest } from '../middleware/validateRequest.js';
import { simulateScenarioSchema, createScenarioSchema } from '../validations/scenario.validation.js';

const router = Router();

router.use(authenticateUser);

router.get('/', getScenarios);
router.get('/company/:companyId', getScenariosByCompanyId);
router.post('/simulate', validateRequest(simulateScenarioSchema), simulateScenario);
router.get('/:id', getScenarioById);
router.post('/', validateRequest(createScenarioSchema), createScenario);
router.put('/:id', updateScenario);
router.delete('/:id', deleteScenario);

export default router;
