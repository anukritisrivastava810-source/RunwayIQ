import { ScenarioService } from '../services/scenario.service.js';
import { ApiResponse } from '../utils/ApiResponse.js';
import { asyncHandler } from '../middleware/asyncHandler.js';

const scenarioService = new ScenarioService();

export const getScenarios = asyncHandler(async (req, res) => {
  const { skip = 0, take = 10 } = req.query;
  const data = await scenarioService.getAllScenarios(Number(skip), Number(take));
  res.status(200).json(new ApiResponse(200, data, 'Scenarios retrieved successfully'));
});

export const getScenarioById = asyncHandler(async (req, res) => {
  const data = await scenarioService.getScenarioById(req.params.id);
  res.status(200).json(new ApiResponse(200, data, 'Scenario retrieved successfully'));
});

export const createScenario = asyncHandler(async (req, res) => {
  const data = await scenarioService.createScenario(req.body);
  res.status(201).json(new ApiResponse(201, data, 'Scenario created successfully'));
});

export const updateScenario = asyncHandler(async (req, res) => {
  const data = await scenarioService.updateScenario(req.params.id, req.body);
  res.status(200).json(new ApiResponse(200, data, 'Scenario updated successfully'));
});

export const deleteScenario = asyncHandler(async (req, res) => {
  await scenarioService.deleteScenario(req.params.id);
  res.status(200).json(new ApiResponse(200, null, 'Scenario deleted successfully'));
});
