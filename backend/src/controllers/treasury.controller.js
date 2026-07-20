import { TreasuryService } from '../services/treasury.service.js';
import { ApiResponse } from '../utils/ApiResponse.js';
import { asyncHandler } from '../middleware/asyncHandler.js';

const treasuryService = new TreasuryService();

export const getTreasurys = asyncHandler(async (req, res) => {
  const { skip = 0, take = 10 } = req.query;
  const data = await treasuryService.getAllTreasurys(Number(skip), Number(take));
  res.status(200).json(new ApiResponse(200, data, 'Treasurys retrieved successfully'));
});

export const getTreasuryById = asyncHandler(async (req, res) => {
  const data = await treasuryService.getTreasuryById(req.params.id);
  res.status(200).json(new ApiResponse(200, data, 'Treasury retrieved successfully'));
});

export const createTreasury = asyncHandler(async (req, res) => {
  const data = await treasuryService.createTreasury(req.body);
  res.status(201).json(new ApiResponse(201, data, 'Treasury created successfully'));
});

export const updateTreasury = asyncHandler(async (req, res) => {
  const data = await treasuryService.updateTreasury(req.params.id, req.body);
  res.status(200).json(new ApiResponse(200, data, 'Treasury updated successfully'));
});

export const deleteTreasury = asyncHandler(async (req, res) => {
  await treasuryService.deleteTreasury(req.params.id);
  res.status(200).json(new ApiResponse(200, null, 'Treasury deleted successfully'));
});
