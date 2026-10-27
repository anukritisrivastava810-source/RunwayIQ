import { TreasuryService } from '../services/treasury.service.js';
import { ApiResponse } from '../utils/ApiResponse.js';
import { ApiError } from '../utils/ApiError.js';
import { asyncHandler } from '../middleware/asyncHandler.js';
import { isValidUUID } from '../utils/validators.js';

const treasuryService = new TreasuryService();

export const getTreasurys = asyncHandler(async (req, res) => {
  const { skip = 0, take = 50, companyId } = req.query;
  const data = companyId
    ? await treasuryService.getByCompany(companyId)
    : await treasuryService.getAllTreasurys(Number(skip), Number(take));
  res.status(200).json(new ApiResponse(200, data, 'Treasurys retrieved successfully'));
});

export const getTreasurysByCompanyId = asyncHandler(async (req, res) => {
  const { companyId } = req.params;
  const data = await treasuryService.getByCompany(companyId);
  res.status(200).json(new ApiResponse(200, data, 'Company treasurys retrieved successfully'));
});

export const getTreasuryById = asyncHandler(async (req, res) => {
  const data = await treasuryService.getTreasuryById(req.params.id);
  res.status(200).json(new ApiResponse(200, data, 'Treasury retrieved successfully'));
});

export const getTreasuryQuote = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { persist, forceRefresh, allowStale } = req.query;

  if (!isValidUUID(id)) {
    throw new ApiError(400, 'Invalid treasury investment ID format');
  }

  const options = {
    persist: persist !== 'false',
    forceRefresh: forceRefresh === 'true',
    allowStale: allowStale === 'true',
  };

  const data = await treasuryService.getInvestmentQuote(id, req.user?.companyId, options);
  res.status(200).json(new ApiResponse(200, data, 'Market quote retrieved successfully'));
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
