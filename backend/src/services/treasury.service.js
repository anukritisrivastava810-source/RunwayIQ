import { TreasuryRepository } from '../repositories/treasury.repository.js';
import prisma from '../config/prisma.js';

const repository = new TreasuryRepository();

export class TreasuryService {
  async createTreasury(data) {
    return await repository.create(data);
  }

  async getTreasuryById(id) {
    return await repository.findById(id);
  }

  async getAllTreasurys(skip, take) {
    return await repository.findAll(skip, take);
  }

  async updateTreasury(id, data) {
    return await repository.update(id, data);
  }

  async deleteTreasury(id) {
    return await repository.delete(id);
  }

  async getByCompany(companyId) {
    return await repository.findByCompany(companyId);
  }

  /**
   * Calculates comprehensive portfolio analytics
   */
  async getPortfolioSummary(companyId) {
    // Fetch all active investments
    const investments = await prisma.treasuryInvestment.findMany({
      where: { companyId }
    });

    let portfolioValue = 0;
    let totalInvested = 0;
    let totalQuantity = 0;
    
    // TODO: Integrate live market API (e.g. Plaid/Alpaca) to fetch real-time 'currentPrice'
    // For now, use purchasePrice as market price if currentPrice is null
    
    const assetDistribution = {};

    investments.forEach(inv => {
      const priceToUse = Number(inv.currentPrice || inv.purchasePrice);
      const units = Number(inv.units || 1);
      const invested = Number(inv.totalInvested);
      const currentValue = priceToUse * units;

      portfolioValue += currentValue;
      totalInvested += invested;
      totalQuantity += units;

      if (!assetDistribution[inv.assetType]) {
        assetDistribution[inv.assetType] = { value: 0, invested: 0 };
      }
      assetDistribution[inv.assetType].value += currentValue;
      assetDistribution[inv.assetType].invested += invested;
    });

    const gainLoss = portfolioValue - totalInvested;
    const gainLossPercent = totalInvested > 0 ? (gainLoss / totalInvested) * 100 : 0;
    
    const investmentAllocation = Object.keys(assetDistribution).map(type => ({
      assetType: type,
      allocationPercent: portfolioValue > 0 ? (assetDistribution[type].value / portfolioValue) * 100 : 0,
      currentValue: assetDistribution[type].value
    }));

    return {
      portfolioValue,
      totalInvested,
      totalQuantity,
      investmentGainLoss: gainLoss,
      investmentGainLossPercent: gainLossPercent,
      assetDistribution,
      investmentAllocation
    };
  }
}
