import Redis from "ioredis";

let redisConfig: any;

if (process.env.REDIS_URI) {
  console.log("Using Redis URI for connection");
  redisConfig = process.env.REDIS_URI;
} else {
  console.log("Using individual Redis config values");
  redisConfig = {
    host: process.env.REDIS_HOST || "redis",
    port: parseInt(process.env.REDIS_PORT || "6379"),
    password: process.env.REDIS_PASSWORD
  };
}

// Add common options
if (typeof redisConfig === 'object') {
  redisConfig = {
    ...redisConfig,
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
}

console.log("Redis connection mode:", typeof redisConfig === 'string' ? 'URI' : 'Config Object');

export const redis = new Redis(redisConfig);

redis.on("error", (error) => {
  if (error.message.includes('WRONGPASS')) {
    console.error("Redis authentication failed. Please check your Redis password configuration.");
  } else if (error.message.includes('ECONNREFUSED')) {
    console.error("Redis connection refused. Please check Redis connection settings and ensure Redis is running.");
  } else {
    console.error("Redis connection error:", error);
  }
});

redis.on("connect", () => {
  console.log("Connected to Redis successfully");
});

export const REDIS_URI_CONNECTION = process.env.REDIS_URI || "";
export const REDIS_OPT_LIMITER_MAX = process.env.REDIS_OPT_LIMITER_MAX || 1;
export const REDIS_OPT_LIMITER_DURATION = process.env.REDIS_OPT_LIMITER_DURATION || 3000;
