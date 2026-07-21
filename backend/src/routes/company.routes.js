import { Router } from 'express';
import companyController from '../controllers/company.controller.js';

const router = Router();

router.post('/', companyController.createCompany);
router.get('/', companyController.getAllCompanies);
router.get('/:id', companyController.getCompanyById);
router.get('/name/:name', companyController.getCompanyByName);
router.put('/:id', companyController.updateCompany);
router.delete('/:id', companyController.deleteCompany);

export default router;
