import { ScenarioRepository } from '../repositories/scenario.repository.js';
import { AnalyticsService } from './analytics.service.js';
import prisma from '../config/prisma.js';
import { ApiError } from '../utils/ApiError.js';

const repository = new ScenarioRepository();
const analyticsService = new AnalyticsService();

export class ScenarioService {
  async createScenario(data) {
    return await repository.create(data);
  }

  async getScenarioById(id) {
    return await repository.findById(id);
  }

  async getAllScenarios(skip, take, where = {}) {
    return await repository.findAll(skip, take, where);
  }

  async updateScenario(id, data) {
    return await repository.update(id, data);
  }

  async deleteScenario(id) {
    return await repository.delete(id);
  }

  async getByCompany(companyId) {
    const company = await prisma.company.findUnique({
      where: { id: companyId },
    });
    if (!company) {
      throw new ApiError(404, 'Company not found');
    }
    return await repository.findByCompany(companyId);
  }

  /**
   * Scenario Simulator
   * Recalculates Burn, Runway, and Cash without modifying records.
   * Return simulated values only.
   */
  async simulateScenario(companyId, adjustments = {}) {
    const company = await prisma.company.findUnique({
      where: { id: companyId },
    });
    if (!company) {
      throw new ApiError(404, 'Company not found');
    }

    const { additionalBurn = 0, additionalRevenue = 0, additionalCash = 0 } = adjustments;
    
    // Fetch baseline
    const baseCash = await analyticsService.getCurrentCash(companyId);
    const baseBurn = await analyticsService.getMonthlyBurnRate(companyId);

    // Apply adjustments
    const simulatedCash = baseCash + Number(additionalCash);
    const simulatedBurn = baseBurn + Number(additionalBurn) - Number(additionalRevenue);

    // Recalculate Runway
    // Established financial formulas:
    // Runway = Cash / Monthly Burn Rate (when Burn > 0)
    // When Burn <= 0, burn is zero or negative (cash-flow break-even or positive), runway is Infinity.
    // If cash is depleted (Cash <= 0), runway is 0.
    let simulatedRunway = Infinity;
    if (simulatedBurn > 0) {
      simulatedRunway = simulatedCash <= 0 ? 0 : simulatedCash / simulatedBurn;
    } else if (simulatedCash <= 0) {
      simulatedRunway = 0;
    }

    let baseRunway = Infinity;
    if (baseBurn > 0) {
      baseRunway = baseCash <= 0 ? 0 : baseCash / baseBurn;
    } else if (baseCash <= 0) {
      baseRunway = 0;
    }

    return {
      baseline: {
        cash: baseCash,
        burn: baseBurn,
        runway: baseRunway
      },
      simulated: {
        cash: simulatedCash,
        burn: simulatedBurn,
        runway: simulatedRunway
      },
      adjustments: {
        additionalBurn: Number(additionalBurn),
        additionalRevenue: Number(additionalRevenue),
        additionalCash: Number(additionalCash)
      }
    };
  }
}
