import { EmployeeService } from '../services/employee.service.js';
import { ApiResponse } from '../utils/ApiResponse.js';
import { asyncHandler } from '../middleware/asyncHandler.js';

const employeeService = new EmployeeService();

export const getEmployees = asyncHandler(async (req, res) => {
  const { skip = 0, take = 10 } = req.query;
  const data = await employeeService.getAllEmployees(Number(skip), Number(take));
  res.status(200).json(new ApiResponse(200, data, 'Employees retrieved successfully'));
});

export const getEmployeeById = asyncHandler(async (req, res) => {
  const data = await employeeService.getEmployeeById(req.params.id);
  res.status(200).json(new ApiResponse(200, data, 'Employee retrieved successfully'));
});

export const createEmployee = asyncHandler(async (req, res) => {
  const data = await employeeService.createEmployee(req.body);
  res.status(201).json(new ApiResponse(201, data, 'Employee created successfully'));
});

export const updateEmployee = asyncHandler(async (req, res) => {
  const data = await employeeService.updateEmployee(req.params.id, req.body);
  res.status(200).json(new ApiResponse(200, data, 'Employee updated successfully'));
});

export const deleteEmployee = asyncHandler(async (req, res) => {
  await employeeService.deleteEmployee(req.params.id);
  res.status(200).json(new ApiResponse(200, null, 'Employee deleted successfully'));
});
