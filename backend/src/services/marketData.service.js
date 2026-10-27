import { ApiError } from '../utils/ApiError.js';
import { logger } from '../utils/logger.js';
import { CONSTANTS } from '../config/constants.js';
import { env } from '../config/env.js';

export class MarketDataService {
  /**
   * @param {string} [apiKey] Twelve Data API Key
   * @param {string} [baseUrl] Base URL for Twelve Data API
   * @param {number} [timeoutMs] Request timeout in milliseconds
   * @param {number} [cacheTtlMs] Cache TTL in milliseconds
   */
  constructor(
    apiKey = process.env.TWELVE_DATA_API_KEY,
    baseUrl = process.env.TWELVE_DATA_BASE_URL || 'https://api.twelvedata.com',
    timeoutMs = CONSTANTS.MARKET_DATA?.DEFAULT_TIMEOUT_MS || 8000,
    cacheTtlMs = env.marketDataCacheTtlMs || CONSTANTS.MARKET_DATA?.DEFAULT_CACHE_TTL_MS || 900000
  ) {
    this.apiKey = apiKey;
    this.baseUrl = (baseUrl || 'https://api.twelvedata.com').replace(/\/+$/, '');
    this.timeoutMs = timeoutMs;
    this.cacheTtlMs = cacheTtlMs;
    this.cache = new Map();
    this.pendingRequests = new Map();
  }

  /**
   * Validates and normalizes ticker symbol
   * @param {string} ticker
   * @returns {string} Normalized uppercase ticker
   */
  validateTicker(ticker) {
    if (!ticker || typeof ticker !== 'string' || !ticker.trim()) {
      throw new ApiError(400, 'Ticker symbol is required and must be a non-empty string');
    }

    const cleaned = ticker.trim().toUpperCase();

    // Standard ticker format: letters, numbers, dot, hyphen, colon, slash (for crypto pairs like BTC/USD)
    if (!/^[A-Z0-9.\-:\/]{1,20}$/.test(cleaned)) {
      throw new ApiError(400, `Invalid ticker symbol format: '${ticker}'`);
    }

    return cleaned;
  }

  /**
   * Generates a normalized cache key based on ticker and currency
   * @param {string} symbol
   * @param {string|null} [currency]
   * @returns {string}
   */
  getCacheKey(symbol, currency = null) {
    const normSymbol = this.validateTicker(symbol);
    const normCurrency = currency ? String(currency).trim().toUpperCase() : 'DEFAULT';
    return `${normSymbol}:${normCurrency}`;
  }

  /**
   * Retrieves an item from the cache if available
   * @param {string} symbol
   * @param {string|null} [currency]
   * @returns {{ entry: object, isExpired: boolean } | null}
   */
  getFromCache(symbol, currency = null) {
    const key = this.getCacheKey(symbol, currency);
    const entry = this.cache.get(key);
    if (!entry) return null;

    const now = Date.now();
    const isExpired = now >= entry.expiresAt;
    return { entry, isExpired };
  }

  /**
   * Stores quote in in-memory cache with specified TTL
   * @param {string} symbol
   * @param {string|null} currency
   * @param {object} data
   * @param {number} [ttlMs]
   */
  setCache(symbol, currency, data, ttlMs = this.cacheTtlMs) {
    const key = this.getCacheKey(symbol, currency);
    const now = Date.now();
    const entry = {
      ...data,
      fetchedAt: now,
      expiresAt: now + ttlMs,
    };
    this.cache.set(key, entry);
    return entry;
  }

  /**
   * Clears the entire cache and pending requests (useful for tests)
   */
  clearCache() {
    this.cache.clear();
    this.pendingRequests.clear();
  }

  /**
   * Deletes a specific ticker from cache
   * @param {string} symbol
   * @param {string|null} [currency]
   */
  invalidate(symbol, currency = null) {
    const key = this.getCacheKey(symbol, currency);
    this.cache.delete(key);
  }

  /**
   * Returns cache metrics
   */
  getCacheStats() {
    return {
      size: this.cache.size,
      pendingRequests: this.pendingRequests.size,
      keys: Array.from(this.cache.keys()),
    };
  }

  /**
   * Internal fetch method to communicate with Twelve Data API
   * @private
   */
  async _fetchFromProvider(symbol, currency, ttlMs) {
    if (!this.apiKey) {
      throw new ApiError(500, 'Market data provider API key is not configured');
    }

    const url = `${this.baseUrl}/price?symbol=${encodeURIComponent(symbol)}&apikey=${this.apiKey}`;
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), this.timeoutMs);

    let response;
    let data;

    try {
      response = await fetch(url, {
        signal: controller.signal,
        headers: {
          'Accept': 'application/json',
        },
      });
    } catch (err) {
      clearTimeout(timeoutId);
      if (err.name === 'AbortError') {
        throw new ApiError(504, `Market data request timed out after ${this.timeoutMs}ms`);
      }
      logger.error(`Network error connecting to market data provider: ${err.message}`);
      throw new ApiError(502, `Failed to connect to market data provider: ${err.message}`);
    } finally {
      clearTimeout(timeoutId);
    }

    try {
      data = await response.json();
    } catch (err) {
      throw new ApiError(502, 'Malformed response from market data provider: invalid JSON');
    }

    // Handle Twelve Data error payloads (Twelve Data typically returns { status: "error", code: 4xx, message: "..." })
    if (data && (data.status === 'error' || (data.code !== undefined && Number(data.code) !== 200))) {
      const code = Number(data.code);
      const message = data.message || 'Market data provider error';

      if (code === 401 || /apikey|api_key|authentication|unauthorized/i.test(message)) {
        throw new ApiError(502, 'Market data provider authentication failed');
      }

      if (code === 429 || /rate limit|call limit|credits/i.test(message)) {
        throw new ApiError(429, `Market data rate limit exceeded: ${message}`);
      }

      if (code === 404 || code === 400 || /not found|symbol|figi/i.test(message)) {
        throw new ApiError(400, `Invalid ticker or symbol not found: '${symbol}'. ${message}`);
      }

      throw new ApiError(502, `Market data provider error: ${message}`);
    }

    if (!response.ok) {
      throw new ApiError(
        response.status >= 500 ? 502 : response.status,
        `Market data provider returned HTTP ${response.status}`
      );
    }

    // Validate that the returned price is numeric and valid
    if (data.price === undefined || data.price === null || String(data.price).trim() === '') {
      throw new ApiError(502, 'Malformed response from market data provider: missing price field');
    }

    const numericPrice = Number(data.price);
    if (isNaN(numericPrice) || numericPrice < 0) {
      throw new ApiError(502, `Malformed response from market data provider: invalid numeric price '${data.price}'`);
    }

    const retrievedAt = new Date().toISOString();
    const quoteData = {
      ticker: symbol,
      price: numericPrice,
      currency: currency || null,
      retrievedAt,
    };

    // Store in cache
    this.setCache(symbol, currency, quoteData, ttlMs);

    return {
      ...quoteData,
      cached: false,
      cacheStatus: 'MISS',
      source: 'LIVE',
      ageSeconds: 0,
      isRealTime: false,
      isStale: false,
    };
  }

  /**
   * Fetches the latest price for a ticker from cache or Twelve Data /price endpoint
   * Coalesces concurrent in-flight requests for the same ticker to prevent duplicate API hits
   * @param {string} ticker Ticker symbol (e.g. 'AAPL', 'SPY', 'BTC/USD')
   * @param {string} [currency] Optional currency hint
   * @param {object} [options] Options: { forceRefresh, allowStale, ttlMs }
   * @returns {Promise<{ ticker: string, price: number, currency: string|null, retrievedAt: string, cached: boolean, cacheStatus: string, source: string, ageSeconds: number, isRealTime: boolean, isStale: boolean }>}
   */
  async getPrice(ticker, currency = null, options = {}) {
    const { forceRefresh = false, allowStale = false, ttlMs = this.cacheTtlMs } = options;
    const symbol = this.validateTicker(ticker);
    const cacheKey = this.getCacheKey(symbol, currency);

    // 1. Check in-memory cache
    if (!forceRefresh) {
      const cached = this.getFromCache(symbol, currency);
      if (cached && !cached.isExpired) {
        const { entry } = cached;
        const ageSeconds = Math.max(0, Math.floor((Date.now() - entry.fetchedAt) / 1000));
        return {
          ticker: entry.ticker,
          price: entry.price,
          currency: entry.currency,
          retrievedAt: entry.retrievedAt,
          cached: true,
          cacheStatus: 'HIT',
          source: 'CACHE',
          ageSeconds,
          isRealTime: false,
          isStale: false,
        };
      }
    }

    // 2. In-flight request deduplication (Promise Coalescing)
    if (this.pendingRequests.has(cacheKey)) {
      return await this.pendingRequests.get(cacheKey);
    }

    // 3. Initiate fetch and register in pendingRequests
    const fetchPromise = (async () => {
      try {
        return await this._fetchFromProvider(symbol, currency, ttlMs);
      } catch (err) {
        // If provider fails and allowStale is enabled, check if an expired cache entry exists
        if (allowStale) {
          const cached = this.getFromCache(symbol, currency);
          if (cached) {
            const { entry } = cached;
            const ageSeconds = Math.max(0, Math.floor((Date.now() - entry.fetchedAt) / 1000));
            logger.warn(`Provider failed for ticker '${symbol}'. Returning stale cache entry from ${entry.retrievedAt}`);
            return {
              ticker: entry.ticker,
              price: entry.price,
              currency: entry.currency,
              retrievedAt: entry.retrievedAt,
              cached: true,
              cacheStatus: 'STALE',
              source: 'STALE',
              ageSeconds,
              isRealTime: false,
              isStale: true,
              staleReason: `Provider error: ${err.message}`,
            };
          }
        }
        throw err;
      } finally {
        this.pendingRequests.delete(cacheKey);
      }
    })();

    this.pendingRequests.set(cacheKey, fetchPromise);
    return await fetchPromise;
  }
}

export const marketDataService = new MarketDataService();
