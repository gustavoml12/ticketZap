import Redis from "ioredis";

const redisUrl = process.env.REDIS_URI;

if (!redisUrl) {
  throw new Error("REDIS_URI environment variable is required");
}

console.log("Attempting Redis connection with URI");

export const redis = new Redis(redisUrl);

redis.on("error", (error) => {
  if (error.message.includes('WRONGPASS')) {
    console.error("Redis authentication failed. Please check your Redis password configuration.");
  } else if (error.message.includes('ECONNREFUSED')) {
    console.error(`Redis connection refused. Please check if Redis is running and network connectivity.`);
  } else if (error.message.includes('ETIMEDOUT')) {
    console.error(`Redis connection timed out. Please check network connectivity.`);
  } else {
    console.error("Redis connection error:", error.message);
  }
});

redis.on("connect", () => {
  console.log("Successfully connected to Redis");
});

redis.on("ready", () => {
  console.log("Redis client is ready to accept commands");
});

export const REDIS_URI_CONNECTION = process.env.REDIS_URI || "";
export const REDIS_OPT_LIMITER_MAX = process.env.REDIS_OPT_LIMITER_MAX || 1;
export const REDIS_OPT_LIMITER_DURATION = process.env.REDIS_OPT_LIMITER_DURATION || 3000;
