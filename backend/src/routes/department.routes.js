import { Router } from 'express';
import { getDepartments, getDepartmentsByCompanyId, getDepartmentById, createDepartment, updateDepartment, deleteDepartment } from '../controllers/department.controller.js';
// import { authenticateUser } from '../middleware/auth.middleware.js';

const router = Router();

// router.use(authenticateUser);

router.get('/', getDepartments);
router.get('/company/:companyId', getDepartmentsByCompanyId);
router.get('/:id', getDepartmentById);
router.post('/', createDepartment);
router.put('/:id', updateDepartment);
router.delete('/:id', deleteDepartment);

export default router;
