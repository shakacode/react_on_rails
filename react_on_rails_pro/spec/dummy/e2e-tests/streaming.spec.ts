import {
  redisReceiverPageTest,
  redisReceiverInsideRouterPageTest,
  redisReceiverPageAfterNavigationTest,
} from './fixture';

// Can be used to delay the execution
const delay = (ms: number) => new Promise(resolve => setTimeout(resolve, ms));

// Snapshot testing the best testing strategy for our use case
// Because we need to ensure that any transformation done on the HTML or RSC payload stream won't affect
//   - Order of fallback or components at the page
//   - Any update chunk won't affect previously rendered parts of the page
//   - Rendered component won't get back to its fallback component at any stage of the page
//   - Snapshot testing saves huge number of complex assertions
([
  ['RedisReceiver', redisReceiverPageTest],
  ['RedisReceiver inside router page', redisReceiverInsideRouterPageTest],
  ['RedisReceiver inside router after navigation', redisReceiverPageAfterNavigationTest],
] as const).forEach(([pageName, test]) => {
  test(`snapshot for page ${pageName}`, async ({ matchPageSnapshot, sendRedisItemValue }) => {
    await matchPageSnapshot('stage0');

    sendRedisItemValue(0, 'Incremental Value1');
    await matchPageSnapshot('stage1');

    sendRedisItemValue(3, 'Incremental Value4');
    await matchPageSnapshot('stage2');

    sendRedisItemValue(1, 'Incremental Value2');
    await matchPageSnapshot('stage3');

    sendRedisItemValue(2, 'Incremental Value3');
    await matchPageSnapshot('stage4');

    sendRedisItemValue(4, 'Incremental Value5');
    await matchPageSnapshot('stage5');
  })
})
