import { Router } from 'express';
import fundingController from '../controllers/funding.controller.js';

const router = Router();

router.post('/', fundingController.createFunding);
router.get('/', fundingController.getAllFundings);
// Ordering is important: static routes before dynamic parameters
router.get('/company/:companyId', fundingController.getFundingByCompanyId);
router.get('/:id', fundingController.getFundingById);
router.put('/:id', fundingController.updateFunding);
router.delete('/:id', fundingController.deleteFunding);

export default router;
