import Redis from "ioredis";

const redisConfig: any = {
  host: process.env.REDIS_HOST || "10.0.2.10",
  port: parseInt(process.env.REDIS_PORT || "6379"),
  retryStrategy: (times: number) => {
    console.log(`Redis retry attempt ${times}`);
    if (times > 20) {
      console.error("Max Redis retries reached, giving up");
      return null; // stop retrying
    }
    const delay = Math.min(times * 100, 3000);
    console.log(`Retrying Redis connection in ${delay}ms`);
    return delay;
  },
  maxRetriesPerRequest: 3,
  showFriendlyErrorStack: true,
  enableAutoPipelining: true,
  connectTimeout: 10000,
  lazyConnect: true,
  reconnectOnError: (err) => {
    const targetError = "READONLY";
    if (err.message.includes(targetError)) {
      return true;
    }
    return false;
  }
};

console.log("Attempting Redis connection with config:", {
  host: redisConfig.host,
  port: redisConfig.port
});

export const redis = new Redis(redisConfig);

redis.on("error", (error) => {
  if (error.message.includes('WRONGPASS')) {
    console.error("Redis authentication failed. Please check your Redis password configuration.");
  } else if (error.message.includes('ECONNREFUSED')) {
    console.error(`Redis connection refused at ${redisConfig.host}:${redisConfig.port}. Please check if Redis is running and network connectivity.`);
  } else if (error.message.includes('ETIMEDOUT')) {
    console.error(`Redis connection timed out at ${redisConfig.host}:${redisConfig.port}. Please check network connectivity.`);
  } else {
    console.error("Redis connection error:", error.message);
  }
});

redis.on("connect", () => {
  console.log(`Successfully connected to Redis at ${redisConfig.host}:${redisConfig.port}`);
});

redis.on("ready", () => {
  console.log("Redis client is ready to process commands");
});

redis.on("reconnecting", () => {
  console.log("Reconnecting to Redis...");
});

export const REDIS_URI_CONNECTION = process.env.REDIS_URI || "";
export const REDIS_OPT_LIMITER_MAX = process.env.REDIS_OPT_LIMITER_MAX || 1;
export const REDIS_OPT_LIMITER_DURATION = process.env.REDIS_OPT_LIMITER_DURATION || 3000;
