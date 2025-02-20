import Redis from "ioredis";

// Parse Redis URI if provided, otherwise use individual config values
let redisConfig: any = {
  retryStrategy: (times: number) => {
    const delay = Math.min(times * 50, 2000);
    return delay;
  },
  maxRetriesPerRequest: 5,
  showFriendlyErrorStack: true,
  enableAutoPipelining: true,
  connectTimeout: 10000,
  lazyConnect: true
};

if (process.env.REDIS_URI) {
  // Use the full URI if provided
  redisConfig = process.env.REDIS_URI;
} else {
  // Otherwise use individual config values
  redisConfig.host = process.env.REDIS_HOST || "redis";
  redisConfig.port = parseInt(process.env.REDIS_PORT || "6379");
  
  if (process.env.REDIS_PASSWORD) {
    redisConfig.password = process.env.REDIS_PASSWORD;
  }
}

console.log("Redis config:", {
  host: redisConfig.host || 'from URI',
  port: redisConfig.port || 'from URI',
  hasPassword: !!redisConfig.password || 'from URI'
});

export const redis = new Redis(redisConfig);

redis.on("error", (error) => {
  if (error.message.includes('WRONGPASS')) {
    console.error("Redis authentication failed. Please check your Redis password configuration.");
  } else if (error.message.includes('ECONNREFUSED')) {
    console.error(`Redis connection refused. Please check if Redis is running at ${redisConfig.host || 'configured host'}:${redisConfig.port || 'configured port'}`);
  } else {
    console.error("Redis connection error:", error);
  }
});

redis.on("connect", () => {
  console.log("Connected to Redis successfully");
});

export const REDIS_URI_CONNECTION = process.env.REDIS_URI || "";
export const REDIS_OPT_LIMITER_MAX = process.env.REDIS_OPT_LIMITER_MAX || 1;
export const REDIS_OPT_LIMITER_DURATION =
  process.env.REDIS_OPT_LIMITER_DURATION || 3000;
