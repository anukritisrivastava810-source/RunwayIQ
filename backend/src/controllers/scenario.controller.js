import { ScenarioService } from '../services/scenario.service.js';
import { ApiResponse } from '../utils/ApiResponse.js';
import { ApiError } from '../utils/ApiError.js';
import { asyncHandler } from '../middleware/asyncHandler.js';
import { isValidUUID } from '../utils/validators.js';
import prisma from '../config/prisma.js';

const scenarioService = new ScenarioService();

export const getScenarios = asyncHandler(async (req, res) => {
  const { skip = 0, take = 10, companyId } = req.query;
  const targetCompanyId = companyId || req.user?.companyId;

  if (companyId) {
    if (!isValidUUID(companyId)) {
      throw new ApiError(400, 'Invalid company ID format');
    }
    if (req.user?.companyId && req.user.companyId !== companyId) {
      throw new ApiError(403, 'Forbidden: You do not have access to this company');
    }
  }

  let data;
  if (targetCompanyId) {
    data = await scenarioService.getByCompany(targetCompanyId);
  } else {
    data = await scenarioService.getAllScenarios(Number(skip), Number(take));
  }

  res.status(200).json(new ApiResponse(200, data, 'Scenarios retrieved successfully'));
});

export const getScenariosByCompanyId = asyncHandler(async (req, res) => {
  const { companyId } = req.params;

  if (!isValidUUID(companyId)) {
    throw new ApiError(400, 'Invalid company ID format');
  }

  if (req.user?.companyId && req.user.companyId !== companyId) {
    throw new ApiError(403, 'Forbidden: You do not have access to this company');
  }

  const data = await scenarioService.getByCompany(companyId);
  res.status(200).json(new ApiResponse(200, data, 'Scenarios retrieved successfully'));
});

export const getScenarioById = asyncHandler(async (req, res) => {
  const { id } = req.params;

  if (!isValidUUID(id)) {
    throw new ApiError(400, 'Invalid scenario ID format');
  }

  const data = await scenarioService.getScenarioById(id);
  if (!data) {
    throw new ApiError(404, 'Scenario not found');
  }

  if (req.user?.companyId && data.companyId !== req.user.companyId) {
    throw new ApiError(403, 'Forbidden: You do not have access to this scenario');
  }

  res.status(200).json(new ApiResponse(200, data, 'Scenario retrieved successfully'));
});

export const createScenario = asyncHandler(async (req, res) => {
  const companyId = req.body.companyId || req.user?.companyId;

  if (!companyId) {
    throw new ApiError(400, 'Company ID is required');
  }

  if (!isValidUUID(companyId)) {
    throw new ApiError(400, 'Invalid company ID format');
  }

  if (req.user?.companyId && req.body.companyId && req.body.companyId !== req.user.companyId) {
    throw new ApiError(403, 'Forbidden: You do not have access to this company');
  }

  const company = await prisma.company.findUnique({ where: { id: companyId } });
  if (!company) {
    throw new ApiError(404, 'Company not found');
  }

  const data = await scenarioService.createScenario({
    ...req.body,
    companyId,
  });

  res.status(201).json(new ApiResponse(201, data, 'Scenario created successfully'));
});

export const updateScenario = asyncHandler(async (req, res) => {
  const { id } = req.params;

  if (!isValidUUID(id)) {
    throw new ApiError(400, 'Invalid scenario ID format');
  }

  const existingScenario = await scenarioService.getScenarioById(id);
  if (!existingScenario) {
    throw new ApiError(404, 'Scenario not found');
  }

  if (req.user?.companyId && existingScenario.companyId !== req.user.companyId) {
    throw new ApiError(403, 'Forbidden: You do not have access to this scenario');
  }

  const data = await scenarioService.updateScenario(id, req.body);
  res.status(200).json(new ApiResponse(200, data, 'Scenario updated successfully'));
});

export const deleteScenario = asyncHandler(async (req, res) => {
  const { id } = req.params;

  if (!isValidUUID(id)) {
    throw new ApiError(400, 'Invalid scenario ID format');
  }

  const existingScenario = await scenarioService.getScenarioById(id);
  if (!existingScenario) {
    throw new ApiError(404, 'Scenario not found');
  }

  if (req.user?.companyId && existingScenario.companyId !== req.user.companyId) {
    throw new ApiError(403, 'Forbidden: You do not have access to this scenario');
  }

  await scenarioService.deleteScenario(id);
  res.status(200).json(new ApiResponse(200, null, 'Scenario deleted successfully'));
});

export const simulateScenario = asyncHandler(async (req, res) => {
  let { companyId, scenarioId, additionalBurn, additionalRevenue, additionalCash } = req.body;

  let existingScenario = null;
  if (scenarioId) {
    if (!isValidUUID(scenarioId)) {
      throw new ApiError(400, 'Invalid scenario ID format');
    }

    existingScenario = await scenarioService.getScenarioById(scenarioId);
    if (!existingScenario) {
      throw new ApiError(404, 'Scenario not found');
    }

    if (companyId && existingScenario.companyId !== companyId) {
      throw new ApiError(400, 'Invalid company/scenario association: Scenario does not belong to the specified company');
    }

    companyId = existingScenario.companyId;
  }

  if (!companyId) {
    throw new ApiError(400, 'Either companyId or scenarioId is required');
  }

  if (!isValidUUID(companyId)) {
    throw new ApiError(400, 'Invalid company ID format');
  }

  if (req.user?.companyId && req.user.companyId !== companyId) {
    throw new ApiError(403, 'Forbidden: You do not have access to this company');
  }

  const adjustments = {
    additionalBurn: additionalBurn !== undefined
      ? Number(additionalBurn)
      : (existingScenario ? Number(existingScenario.additionalBurn) : 0),
    additionalRevenue: additionalRevenue !== undefined
      ? Number(additionalRevenue)
      : (existingScenario ? Number(existingScenario.additionalRevenue) : 0),
    additionalCash: additionalCash !== undefined
      ? Number(additionalCash)
      : (existingScenario ? Number(existingScenario.additionalCash) : 0),
  };

  if (isNaN(adjustments.additionalBurn) || isNaN(adjustments.additionalRevenue) || isNaN(adjustments.additionalCash)) {
    throw new ApiError(400, 'Invalid adjustment values: numbers expected');
  }

  const result = await scenarioService.simulateScenario(companyId, adjustments);

  const responseData = {
    companyId,
    ...(existingScenario && {
      scenarioId: existingScenario.id,
      scenarioName: existingScenario.name,
    }),
    ...result,
  };

  res.status(200).json(new ApiResponse(200, responseData, 'Scenario simulation calculated successfully'));
});
