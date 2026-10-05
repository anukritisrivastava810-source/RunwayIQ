import { Router } from 'express';
import { getTreasurys, getTreasurysByCompanyId, getTreasuryById, createTreasury, updateTreasury, deleteTreasury } from '../controllers/treasury.controller.js';
// import { authenticateUser } from '../middleware/auth.middleware.js';

const router = Router();

// router.use(authenticateUser);

router.get('/', getTreasurys);
router.get('/company/:companyId', getTreasurysByCompanyId);
router.get('/:id', getTreasuryById);
router.post('/', createTreasury);
router.put('/:id', updateTreasury);
router.delete('/:id', deleteTreasury);

export default router;
