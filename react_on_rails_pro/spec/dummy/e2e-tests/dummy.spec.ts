// import { test, expect } from '@playwright/test';
// import { redisControlledTest } from './fixture';

// redisControlledTest('test1', ({ redisRequestId, redisClient }) => {
//   console.log('Test1 request id', redisRequestId);
//   console.log(redisClient);
// });

// redisControlledTest('test2', ({ redisRequestId, redisClient }) => {
//   console.log('Test2 request id', redisRequestId);
//   console.log(redisClient);
// });

import { mergeTests } from '@playwright/test';
import { test1, test2 } from './dummt-fixture';

const test = mergeTests(test2);

test('eee', ({ h2 }) => {
  console.log('TEst', h2);
})

