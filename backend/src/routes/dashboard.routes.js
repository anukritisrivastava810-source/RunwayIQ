import { Router } from 'express';
import { getDashboard, getSummary, getRunway, getBurnRate, getPayroll, getBurnTrend } from '../controllers/dashboard.controller.js';
import { authenticateUser } from '../middleware/auth.middleware.js';

const router = Router();

// ── Public company-scoped endpoint (no JWT required — matches Flutter pattern) ──
router.get('/company/:companyId/burn-trend', getBurnTrend);

// ── Auth-protected routes ─────────────────────────────────────────────────────
router.use(authenticateUser);

router.get('/', getDashboard);
router.get('/summary', getSummary);
router.get('/runway', getRunway);
router.get('/burn-rate', getBurnRate);
router.get('/payroll', getPayroll);

export default router;
