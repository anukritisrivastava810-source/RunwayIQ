import { Router } from 'express';
import { getFundings, getFundingById, createFunding, updateFunding, deleteFunding } from '../controllers/funding.controller.js';
import { authenticateUser } from '../middleware/auth.middleware.js';

const router = Router();

router.use(authenticateUser);

router.get('/', getFundings);
router.get('/:id', getFundingById);
router.post('/', createFunding);
router.put('/:id', updateFunding);
router.delete('/:id', deleteFunding);

export default router;
