import dotenv from 'dotenv';

dotenv.config();

export const env = {
  port: process.env.PORT || 3000,
  nodeEnv: process.env.NODE_ENV || 'development',
  twelveDataApiKey: process.env.TWELVE_DATA_API_KEY,
  twelveDataBaseUrl: process.env.TWELVE_DATA_BASE_URL || 'https://api.twelvedata.com',
  marketDataCacheTtlMs: process.env.MARKET_DATA_CACHE_TTL_MS
    ? Number(process.env.MARKET_DATA_CACHE_TTL_MS)
    : 15 * 60 * 1000,
};
