import { Router } from 'express';
import { getExpenses, getExpensesByCompanyId, getExpenseById, createExpense, updateExpense, deleteExpense } from '../controllers/expense.controller.js';
// import { authenticateUser } from '../middleware/auth.middleware.js';

const router = Router();

// router.use(authenticateUser);

router.get('/', getExpenses);
router.get('/company/:companyId', getExpensesByCompanyId);
router.get('/:id', getExpenseById);
router.post('/', createExpense);
router.put('/:id', updateExpense);
router.delete('/:id', deleteExpense);

export default router;
