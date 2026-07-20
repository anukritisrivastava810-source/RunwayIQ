import { InvestorService } from '../services/investor.service.js';
import { ApiResponse } from '../utils/ApiResponse.js';
import { asyncHandler } from '../middleware/asyncHandler.js';

const investorService = new InvestorService();

export const getInvestors = asyncHandler(async (req, res) => {
  const { skip = 0, take = 10 } = req.query;
  const data = await investorService.getAllInvestors(Number(skip), Number(take));
  res.status(200).json(new ApiResponse(200, data, 'Investors retrieved successfully'));
});

export const getInvestorById = asyncHandler(async (req, res) => {
  const data = await investorService.getInvestorById(req.params.id);
  res.status(200).json(new ApiResponse(200, data, 'Investor retrieved successfully'));
});

export const createInvestor = asyncHandler(async (req, res) => {
  const data = await investorService.createInvestor(req.body);
  res.status(201).json(new ApiResponse(201, data, 'Investor created successfully'));
});

export const updateInvestor = asyncHandler(async (req, res) => {
  const data = await investorService.updateInvestor(req.params.id, req.body);
  res.status(200).json(new ApiResponse(200, data, 'Investor updated successfully'));
});

export const deleteInvestor = asyncHandler(async (req, res) => {
  await investorService.deleteInvestor(req.params.id);
  res.status(200).json(new ApiResponse(200, null, 'Investor deleted successfully'));
});
