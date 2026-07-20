import { CompanyService } from '../services/company.service.js';
import { ApiResponse } from '../utils/ApiResponse.js';
import { asyncHandler } from '../middleware/asyncHandler.js';

const companyService = new CompanyService();

export const getCompanys = asyncHandler(async (req, res) => {
  const { skip = 0, take = 10 } = req.query;
  const data = await companyService.getAllCompanys(Number(skip), Number(take));
  res.status(200).json(new ApiResponse(200, data, 'Companys retrieved successfully'));
});

export const getCompanyById = asyncHandler(async (req, res) => {
  const data = await companyService.getCompanyById(req.params.id);
  res.status(200).json(new ApiResponse(200, data, 'Company retrieved successfully'));
});

export const createCompany = asyncHandler(async (req, res) => {
  const data = await companyService.createCompany(req.body);
  res.status(201).json(new ApiResponse(201, data, 'Company created successfully'));
});

export const updateCompany = asyncHandler(async (req, res) => {
  const data = await companyService.updateCompany(req.params.id, req.body);
  res.status(200).json(new ApiResponse(200, data, 'Company updated successfully'));
});

export const deleteCompany = asyncHandler(async (req, res) => {
  await companyService.deleteCompany(req.params.id);
  res.status(200).json(new ApiResponse(200, null, 'Company deleted successfully'));
});
