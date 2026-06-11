import Redis from 'ioredis';

const TOKEN_TTL_SECONDS = 30 * 24 * 60 * 60; // 30 días

export async function registerToken(
  district: string,
  fcmToken: string,
  redis: Redis,
): Promise<void> {
  const key = `zone:${district}:tokens`;
  await redis.sadd(key, fcmToken);
  await redis.expire(key, TOKEN_TTL_SECONDS);
}

export async function getTokensForDistrict(district: string, redis: Redis): Promise<string[]> {
  const key = `zone:${district}:tokens`;
  return redis.smembers(key);
}

export async function removeToken(district: string, fcmToken: string, redis: Redis): Promise<void> {
  const key = `zone:${district}:tokens`;
  await redis.srem(key, fcmToken);
}
