import { FundingService } from '../services/funding.service.js';
import { ApiResponse } from '../utils/ApiResponse.js';
import { asyncHandler } from '../middleware/asyncHandler.js';

const fundingService = new FundingService();

export const getFundings = asyncHandler(async (req, res) => {
  const { skip = 0, take = 10 } = req.query;
  const data = await fundingService.getAllFundings(Number(skip), Number(take));
  res.status(200).json(new ApiResponse(200, data, 'Fundings retrieved successfully'));
});

export const getFundingById = asyncHandler(async (req, res) => {
  const data = await fundingService.getFundingById(req.params.id);
  res.status(200).json(new ApiResponse(200, data, 'Funding retrieved successfully'));
});

export const createFunding = asyncHandler(async (req, res) => {
  const data = await fundingService.createFunding(req.body);
  res.status(201).json(new ApiResponse(201, data, 'Funding created successfully'));
});

export const updateFunding = asyncHandler(async (req, res) => {
  const data = await fundingService.updateFunding(req.params.id, req.body);
  res.status(200).json(new ApiResponse(200, data, 'Funding updated successfully'));
});

export const deleteFunding = asyncHandler(async (req, res) => {
  await fundingService.deleteFunding(req.params.id);
  res.status(200).json(new ApiResponse(200, null, 'Funding deleted successfully'));
});
