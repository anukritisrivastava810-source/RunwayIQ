import { DashboardService } from '../services/dashboard.service.js';
import { ApiResponse } from '../utils/ApiResponse.js';
import { asyncHandler } from '../middleware/asyncHandler.js';

const dashboardService = new DashboardService();

export const getDashboard = asyncHandler(async (req, res) => {
  const data = await dashboardService.getDashboard(req.user.companyId);
  res.status(200).json(new ApiResponse(200, data, 'Dashboard retrieved successfully'));
});

export const getSummary = asyncHandler(async (req, res) => {
  const data = await dashboardService.getFundingSummary(req.user.companyId);
  res.status(200).json(new ApiResponse(200, data, 'Summary retrieved successfully'));
});

export const getRunway = asyncHandler(async (req, res) => {
  const data = await dashboardService.getRunway(req.user.companyId);
  res.status(200).json(new ApiResponse(200, { runway: data }, 'Runway retrieved successfully'));
});

export const getBurnRate = asyncHandler(async (req, res) => {
  const data = await dashboardService.getBurnRate(req.user.companyId);
  res.status(200).json(new ApiResponse(200, { burnRate: data }, 'Burn rate retrieved successfully'));
});

export const getPayroll = asyncHandler(async (req, res) => {
  res.status(200).json(new ApiResponse(200, {}, 'Payroll retrieved successfully'));
});
