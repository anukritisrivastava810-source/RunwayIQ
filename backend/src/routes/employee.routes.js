import { Router } from 'express';
import employeeController from '../controllers/employee.controller.js';

const router = Router();

router.post('/', employeeController.createEmployee);
router.get('/', employeeController.getAllEmployees);
// Ordering is important: static routes before dynamic parameters
router.get('/company/:companyId', employeeController.getEmployeesByCompanyId);
router.get('/:id', employeeController.getEmployeeById);
router.put('/:id', employeeController.updateEmployee);
router.delete('/:id', employeeController.deleteEmployee);

export default router;
