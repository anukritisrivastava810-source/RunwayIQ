import { Router } from 'express';
import { getCompanys, getCompanyById, createCompany, updateCompany, deleteCompany } from '../controllers/company.controller.js';
import { authenticateUser } from '../middleware/auth.middleware.js';

const router = Router();

router.use(authenticateUser);

router.get('/', getCompanys);
router.get('/:id', getCompanyById);
router.post('/', createCompany);
router.put('/:id', updateCompany);
router.delete('/:id', deleteCompany);

export default router;
