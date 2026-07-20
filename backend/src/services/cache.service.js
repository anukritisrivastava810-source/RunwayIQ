import { logger } from '../utils/logger.js';

/**
 * CacheService interface stub for future Redis integration.
 * Currently uses an in-memory map for basic development, but acts as a placeholder.
 */
class CacheService {
  constructor() {
    this.cache = new Map();
  }

  // TODO: Replace with Redis client (e.g. ioredis) in production
  
  async get(key) {
    logger.debug(`Cache GET: ${key}`);
    const data = this.cache.get(key);
    if (!data) return null;

    if (data.expiry && data.expiry < Date.now()) {
      this.cache.delete(key);
      return null;
    }
    return data.value;
  }

  async set(key, value, ttlSeconds = 3600) {
    logger.debug(`Cache SET: ${key}`);
    const expiry = Date.now() + (ttlSeconds * 1000);
    this.cache.set(key, { value, expiry });
  }

  async delete(key) {
    logger.debug(`Cache DELETE: ${key}`);
    this.cache.delete(key);
  }

  async clear() {
    logger.info('Cache CLEARED');
    this.cache.clear();
  }
}

export const cacheService = new CacheService();
