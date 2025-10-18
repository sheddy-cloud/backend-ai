const redis = require('redis');
require('dotenv').config();

// Redis configuration for cloud deployment
const redisConfig = {
  host: process.env.REDIS_HOST || 'localhost',
  port: process.env.REDIS_PORT || 6379,
  password: process.env.REDIS_PASSWORD || undefined,
  retryDelayOnFailover: 100,
  enableReadyCheck: false,
  maxRetriesPerRequest: null,
};

// Create Redis client
const client = redis.createClient(redisConfig);

// Redis connection events
client.on('connect', () => {
  console.log('✅ Connected to Redis');
});

client.on('ready', () => {
  console.log('🚀 Redis client ready');
});

client.on('error', (err) => {
  console.error('❌ Redis connection error:', err);
});

client.on('end', () => {
  console.log('🔒 Redis connection ended');
});

// Connect to Redis
client.connect().catch(console.error);

// Helper functions for caching
const cache = {
  // Set cache with TTL
  set: async (key, value, ttl = 3600) => {
    try {
      const serializedValue = JSON.stringify(value);
      await client.setEx(key, ttl, serializedValue);
      console.log(`💾 Cached: ${key}`);
    } catch (error) {
      console.error('❌ Cache set error:', error);
    }
  },

  // Get from cache
  get: async (key) => {
    try {
      const value = await client.get(key);
      if (value) {
        console.log(`📖 Cache hit: ${key}`);
        return JSON.parse(value);
      }
      console.log(`❌ Cache miss: ${key}`);
      return null;
    } catch (error) {
      console.error('❌ Cache get error:', error);
      return null;
    }
  },

  // Delete from cache
  del: async (key) => {
    try {
      await client.del(key);
      console.log(`🗑️ Deleted from cache: ${key}`);
    } catch (error) {
      console.error('❌ Cache delete error:', error);
    }
  },

  // Clear all cache
  flush: async () => {
    try {
      await client.flushAll();
      console.log('🧹 Cache flushed');
    } catch (error) {
      console.error('❌ Cache flush error:', error);
    }
  }
};

// Graceful shutdown
const closeRedis = async () => {
  try {
    await client.quit();
    console.log('🔒 Redis connection closed');
  } catch (error) {
    console.error('❌ Error closing Redis:', error);
  }
};

module.exports = {
  client,
  cache,
  closeRedis
};
