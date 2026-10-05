import { Router } from 'express';
import { getEmployees, getEmployeesByCompanyId, getEmployeeById, createEmployee, updateEmployee, deleteEmployee } from '../controllers/employee.controller.js';
// import { authenticateUser } from '../middleware/auth.middleware.js';

const router = Router();

// router.use(authenticateUser);

router.get('/', getEmployees);
router.get('/company/:companyId', getEmployeesByCompanyId);
router.get('/:id', getEmployeeById);
router.post('/', createEmployee);
router.put('/:id', updateEmployee);
router.delete('/:id', deleteEmployee);

export default router;
