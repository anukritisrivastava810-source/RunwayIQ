import { TreasuryRepository } from '../repositories/treasury.repository.js';
import { marketDataService } from './marketData.service.js';
import { ApiError } from '../utils/ApiError.js';
import { CONSTANTS } from '../config/constants.js';
import prisma from '../config/prisma.js';

const defaultRepository = new TreasuryRepository();

export class TreasuryService {
  constructor(marketData = marketDataService, repository = defaultRepository) {
    this.marketDataService = marketData;
    this.repository = repository;
  }

  async createTreasury(data) {
    const isMarketAsset = ['STOCK', 'ETF', 'MUTUAL_FUND', 'CRYPTO'].includes(data.assetType);
    if (isMarketAsset) {
      if (!data.ticker || !data.ticker.trim()) {
        throw new ApiError(400, 'Ticker symbol is required for market-priced investments');
      }
      if (data.units == null || Number(data.units) <= 0) {
        throw new ApiError(400, 'Quantity/units must be greater than 0 for market-priced investments');
      }
      if (data.purchasePrice == null || Number(data.purchasePrice) < 0) {
        throw new ApiError(400, 'Purchase price per unit must be non-negative');
      }
    }
    return await this.repository.create(data);
  }

  async getTreasuryById(id) {
    return await this.repository.findById(id);
  }

  async getAllTreasurys(skip, take) {
    return await this.repository.findAll(skip, take);
  }

  async updateTreasury(id, data) {
    if (data.assetType) {
      const isMarketAsset = ['STOCK', 'ETF', 'MUTUAL_FUND', 'CRYPTO'].includes(data.assetType);
      if (isMarketAsset) {
        if (data.ticker !== undefined && (!data.ticker || !data.ticker.trim())) {
          throw new ApiError(400, 'Ticker symbol is required for market-priced investments');
        }
        if (data.units !== undefined && (data.units == null || Number(data.units) <= 0)) {
          throw new ApiError(400, 'Quantity/units must be greater than 0 for market-priced investments');
        }
      }
    }
    return await this.repository.update(id, data);
  }

  async deleteTreasury(id) {
    return await this.repository.delete(id);
  }

  async getByCompany(companyId) {
    return await this.repository.findByCompany(companyId);
  }

  /**
   * Retrieves a market quote for a market-priced treasury investment
   * Safely updates currentPrice and currentValue in the database when units and currency criteria are satisfied
   * @param {string} id Investment UUID
   * @param {string} [userCompanyId] Company ID from authenticated user for company isolation
   * @param {object} [options] { persist: boolean, forceRefresh: boolean, allowStale: boolean }
   */
  async getInvestmentQuote(id, userCompanyId = null, options = {}) {
    const { persist = true, forceRefresh = false, allowStale = false } = options;

    const investment = await this.repository.findById(id);
    if (!investment) {
      throw new ApiError(404, 'Treasury investment not found');
    }

    if (userCompanyId && investment.companyId !== userCompanyId) {
      throw new ApiError(403, 'Forbidden: You do not have access to this investment');
    }

    const unsupportedTypes = CONSTANTS.MARKET_DATA?.UNSUPPORTED_ASSET_TYPES || ['BOND', 'FIXED_DEPOSIT', 'CASH'];
    if (unsupportedTypes.includes(investment.assetType)) {
      throw new ApiError(
        400,
        `Asset type '${investment.assetType}' does not support live market price quotes. Only market-traded assets are supported.`
      );
    }

    if (!investment.ticker || !investment.ticker.trim()) {
      throw new ApiError(400, 'Investment does not have a ticker symbol required for market quotes');
    }

    const quote = await this.marketDataService.getPrice(investment.ticker, investment.currency, {
      forceRefresh,
      allowStale,
    });

    // Determine if we can safely persist currentPrice and currentValue
    let canPersist = Boolean(persist);
    let persistenceReason = null;

    // Safety Check 1: Provider failure / stale quote check
    if (quote.isStale) {
      canPersist = false;
      persistenceReason = 'Cannot persist stale market quote resulting from provider error';
    }

    // Safety Check 2: Currency mismatch check
    if (canPersist && quote.currency && investment.currency) {
      if (String(quote.currency).trim().toUpperCase() !== String(investment.currency).trim().toUpperCase()) {
        canPersist = false;
        persistenceReason = `Currency mismatch: Quote currency (${quote.currency}) does not match investment currency (${investment.currency})`;
      }
    }

    // Safety Check 3: Quantity / Units check
    const units = investment.units != null ? Number(investment.units) : null;
    if (canPersist) {
      if (units === null || isNaN(units) || units <= 0) {
        canPersist = false;
        persistenceReason = 'Missing or invalid investment units/quantity: accurate valuation cannot be calculated without assuming units';
      }
    }

    let calculatedCurrentValue = null;

    if (canPersist && units !== null && units > 0) {
      // currentValue = currentPrice × units
      calculatedCurrentValue = Number((quote.price * units).toFixed(2));

      // Persist currentPrice and currentValue safely
      // Strict rule: NEVER overwrite totalInvested or purchasePrice!
      await this.repository.update(investment.id, {
        currentPrice: quote.price,
        currentValue: calculatedCurrentValue,
      });
    } else if (investment.currentValue != null) {
      calculatedCurrentValue = Number(investment.currentValue);
    }

    const response = {
      investmentId: investment.id,
      companyId: investment.companyId,
      name: investment.name,
      assetType: investment.assetType,
      ticker: quote.ticker,
      price: quote.price,
      currency: quote.currency || investment.currency,
      units: units !== null ? units : null,
      currentValue: calculatedCurrentValue,
      totalInvested: Number(investment.totalInvested || 0),
      persisted: canPersist,
      retrievedAt: quote.retrievedAt,
      cached: quote.cached,
      cacheStatus: quote.cacheStatus,
      source: quote.source,
      ageSeconds: quote.ageSeconds,
      isRealTime: quote.isRealTime,
    };

    if (!canPersist && persistenceReason) {
      response.persistenceReason = persistenceReason;
    }

    return response;
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
    
    const assetDistribution = {};

    investments.forEach(inv => {
      let currentValue;
      let units = 0;
      const isMarketAsset = ['STOCK', 'ETF', 'MUTUAL_FUND', 'CRYPTO'].includes(inv.assetType);

      if (isMarketAsset) {
        if (inv.currentValue != null) {
          currentValue = Number(inv.currentValue);
          units = inv.units != null ? Number(inv.units) : 0;
        } else if (inv.units != null && Number(inv.units) > 0) {
          units = Number(inv.units);
          const priceToUse = Number(inv.currentPrice || inv.purchasePrice);
          currentValue = priceToUse * units;
        } else {
          // Do not assume units = 1 for market-priced investments
          currentValue = Number(inv.totalInvested);
          units = 0;
        }
      } else {
        // CASH, BOND, FIXED_DEPOSIT maintain fixed nominal/yield valuation
        currentValue = Number(inv.currentValue || inv.totalInvested);
        units = inv.units != null ? Number(inv.units) : 1;
      }

      const invested = Number(inv.totalInvested);

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
