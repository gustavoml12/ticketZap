import Redis from "ioredis";

const redisConfig = {
  host: process.env.REDIS_HOST || "redis",
  port: parseInt(process.env.REDIS_PORT || "6379"),
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

// Only add password if it's set
if (process.env.REDIS_PASSWORD) {
  redisConfig['password'] = process.env.REDIS_PASSWORD;
}

export const redis = new Redis(redisConfig);

redis.on("error", (error) => {
  if (error.message.includes('WRONGPASS')) {
    console.error("Redis authentication failed. Please check your Redis password configuration.");
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
