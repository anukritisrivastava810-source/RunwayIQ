import { Router } from 'express';
import { getDashboard, getSummary, getRunway, getBurnRate, getPayroll } from '../controllers/dashboard.controller.js';
import { authenticateUser } from '../middleware/auth.middleware.js';

const router = Router();

router.use(authenticateUser);

router.get('/', getDashboard);
router.get('/summary', getSummary);
router.get('/runway', getRunway);
router.get('/burn-rate', getBurnRate);
router.get('/payroll', getPayroll);

export default router;
