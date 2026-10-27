import { Router } from 'express';
import {
  getTreasurys,
  getTreasurysByCompanyId,
  getTreasuryById,
  getTreasuryQuote,
  createTreasury,
  updateTreasury,
  deleteTreasury,
} from '../controllers/treasury.controller.js';
import { authenticateUser } from '../middleware/auth.middleware.js';

const router = Router();

router.get('/', getTreasurys);
router.get('/company/:companyId', getTreasurysByCompanyId);

// Specific sub-resource route before generic /:id parameter
router.get('/:id/quote', authenticateUser, getTreasuryQuote);

router.get('/:id', getTreasuryById);
router.post('/', createTreasury);
router.put('/:id', updateTreasury);
router.delete('/:id', deleteTreasury);

export default router;
