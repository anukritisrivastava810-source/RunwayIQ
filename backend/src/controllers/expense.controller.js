import { ExpenseService } from '../services/expense.service.js';
import { ApiResponse } from '../utils/ApiResponse.js';
import { asyncHandler } from '../middleware/asyncHandler.js';

const expenseService = new ExpenseService();

export const getExpenses = asyncHandler(async (req, res) => {
  const { skip = 0, take = 10 } = req.query;
  const data = await expenseService.getAllExpenses(Number(skip), Number(take));
  res.status(200).json(new ApiResponse(200, data, 'Expenses retrieved successfully'));
});

export const getExpenseById = asyncHandler(async (req, res) => {
  const data = await expenseService.getExpenseById(req.params.id);
  res.status(200).json(new ApiResponse(200, data, 'Expense retrieved successfully'));
});

export const createExpense = asyncHandler(async (req, res) => {
  const data = await expenseService.createExpense(req.body);
  res.status(201).json(new ApiResponse(201, data, 'Expense created successfully'));
});

export const updateExpense = asyncHandler(async (req, res) => {
  const data = await expenseService.updateExpense(req.params.id, req.body);
  res.status(200).json(new ApiResponse(200, data, 'Expense updated successfully'));
});

export const deleteExpense = asyncHandler(async (req, res) => {
  await expenseService.deleteExpense(req.params.id);
  res.status(200).json(new ApiResponse(200, null, 'Expense deleted successfully'));
});
