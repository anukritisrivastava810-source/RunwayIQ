import { ScenarioRepository } from '../repositories/scenario.repository.js';
import { AnalyticsService } from './analytics.service.js';

const repository = new ScenarioRepository();
const analyticsService = new AnalyticsService();

export class ScenarioService {
  async createScenario(data) {
    return await repository.create(data);
  }

  async getScenarioById(id) {
    return await repository.findById(id);
  }

  async getAllScenarios(skip, take) {
    return await repository.findAll(skip, take);
  }

  async updateScenario(id, data) {
    return await repository.update(id, data);
  }

  async deleteScenario(id) {
    return await repository.delete(id);
  }

  async getByCompany(companyId) {
    return await repository.findByCompany(companyId);
  }

  /**
   * Scenario Simulator
   * Recalculates Burn, Runway, and Cash without modifying records.
   * Return simulated values only.
   */
  async simulateScenario(companyId, adjustments) {
    const { additionalBurn = 0, additionalRevenue = 0, additionalCash = 0 } = adjustments;
    
    // Fetch baseline
    const baseCash = await analyticsService.getCurrentCash(companyId);
    const baseBurn = await analyticsService.getMonthlyBurnRate(companyId);

    // Apply adjustments
    const simulatedCash = baseCash + Number(additionalCash);
    const simulatedBurn = baseBurn + Number(additionalBurn) - Number(additionalRevenue);

    // Recalculate Runway
    let simulatedRunway = Infinity;
    if (simulatedBurn > 0) {
      simulatedRunway = simulatedCash / simulatedBurn;
    }

    return {
      baseline: {
        cash: baseCash,
        burn: baseBurn,
        runway: baseBurn > 0 ? baseCash / baseBurn : Infinity
      },
      simulated: {
        cash: simulatedCash,
        burn: simulatedBurn,
        runway: simulatedRunway
      },
      adjustments
    };
  }
}
