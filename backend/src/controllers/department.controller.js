import { DepartmentService } from '../services/department.service.js';
import { ApiResponse } from '../utils/ApiResponse.js';
import { asyncHandler } from '../middleware/asyncHandler.js';

const departmentService = new DepartmentService();

export const getDepartments = asyncHandler(async (req, res) => {
  const { skip = 0, take = 10 } = req.query;
  const data = await departmentService.getAllDepartments(Number(skip), Number(take));
  res.status(200).json(new ApiResponse(200, data, 'Departments retrieved successfully'));
});

export const getDepartmentById = asyncHandler(async (req, res) => {
  const data = await departmentService.getDepartmentById(req.params.id);
  res.status(200).json(new ApiResponse(200, data, 'Department retrieved successfully'));
});

export const createDepartment = asyncHandler(async (req, res) => {
  const data = await departmentService.createDepartment(req.body);
  res.status(201).json(new ApiResponse(201, data, 'Department created successfully'));
});

export const updateDepartment = asyncHandler(async (req, res) => {
  const data = await departmentService.updateDepartment(req.params.id, req.body);
  res.status(200).json(new ApiResponse(200, data, 'Department updated successfully'));
});

export const deleteDepartment = asyncHandler(async (req, res) => {
  await departmentService.deleteDepartment(req.params.id);
  res.status(200).json(new ApiResponse(200, null, 'Department deleted successfully'));
});
