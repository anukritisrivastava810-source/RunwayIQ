import { Router } from 'express';
import authRoutes from './auth.routes.js';
import companyRoutes from './company.routes.js';
import dashboardRoutes from './dashboard.routes.js';
import employeeRoutes from './employee.routes.js';
import departmentRoutes from './department.routes.js';
import expenseRoutes from './expense.routes.js';
import investorRoutes from './investor.routes.js';
import fundingRoutes from './funding.routes.js';
import treasuryRoutes from './treasury.routes.js';
import scenarioRoutes from './scenario.routes.js';

const router = Router();

router.use('/auth', authRoutes);
router.use('/companies', companyRoutes);
router.use('/dashboard', dashboardRoutes);
router.use('/employees', employeeRoutes);
router.use('/departments', departmentRoutes);
router.use('/expenses', expenseRoutes);
router.use('/investors', investorRoutes);
router.use('/funding', fundingRoutes);
router.use('/treasury', treasuryRoutes);
router.use('/scenarios', scenarioRoutes);

export default router;
