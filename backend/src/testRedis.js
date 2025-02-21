const Redis = require('ioredis');

const redis = new Redis('redis://default:rZzhHPOIoCFkQ72GtiPFmX852eji4fjON2llkUMT4njZneILmtbnQGIAS7TIviNY@hsscggc48w4oo8c84o8ww4ck:6379/0');

redis.on('error', (err) => {
  console.error('Redis Error:', err);
  process.exit(1);
});

redis.on('connect', () => {
  console.log('Successfully connected to Redis!');
  process.exit(0);
});

// Tentar um ping
redis.ping().then(() => {
  console.log('PING successful!');
}).catch(err => {
  console.error('PING failed:', err);
});
