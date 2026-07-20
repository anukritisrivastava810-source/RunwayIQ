import { Router } from 'express';
import { getInvestors, getInvestorById, createInvestor, updateInvestor, deleteInvestor } from '../controllers/investor.controller.js';
import { authenticateUser } from '../middleware/auth.middleware.js';

const router = Router();

router.use(authenticateUser);

router.get('/', getInvestors);
router.get('/:id', getInvestorById);
router.post('/', createInvestor);
router.put('/:id', updateInvestor);
router.delete('/:id', deleteInvestor);

export default router;
