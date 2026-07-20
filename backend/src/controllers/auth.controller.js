import { AuthService } from '../services/auth.service.js';
import { ApiResponse } from '../utils/ApiResponse.js';
import { asyncHandler } from '../middleware/asyncHandler.js';

const authService = new AuthService();

export const login = asyncHandler(async (req, res) => {
  const { email, password } = req.body;
  const data = await authService.login(email, password);
  res.status(200).json(new ApiResponse(200, data, 'Login successful'));
});

export const registerFounder = asyncHandler(async (req, res) => {
  const data = await authService.registerFounder(req.body);
  res.status(201).json(new ApiResponse(201, data, 'Founder registered successfully'));
});

export const logout = asyncHandler(async (req, res) => {
  res.status(200).json(new ApiResponse(200, null, 'Logout successful'));
});
