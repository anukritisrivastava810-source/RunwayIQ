import { Router } from 'express';
import { getScenarios, getScenarioById, createScenario, updateScenario, deleteScenario } from '../controllers/scenario.controller.js';
import { authenticateUser } from '../middleware/auth.middleware.js';

const router = Router();

router.use(authenticateUser);

router.get('/', getScenarios);
router.get('/:id', getScenarioById);
router.post('/', createScenario);
router.put('/:id', updateScenario);
router.delete('/:id', deleteScenario);

export default router;
