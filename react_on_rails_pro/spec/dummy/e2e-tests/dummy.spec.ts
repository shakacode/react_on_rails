import { test, expect } from '@playwright/test';
import { redisControlledTest } from './fixture';

redisControlledTest('test1', ({ redisRequestId, redisClient }) => {
  console.log('Test1 request id', redisRequestId);
  console.log(redisClient);
});

redisControlledTest('test2', ({ redisRequestId, redisClient }) => {
  console.log('Test2 request id', redisRequestId);
  console.log(redisClient);
});
