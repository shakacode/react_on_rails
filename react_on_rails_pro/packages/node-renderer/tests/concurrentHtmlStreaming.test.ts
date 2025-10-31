import { randomUUID } from 'crypto';
import { createClient } from 'redis';

import buildApp from '../src/worker';
import config from './testingNodeRendererConfigs';
import { makeRequest } from './httpRequestUtils';
import { Config } from '../src/shared/configBuilder';

const app = buildApp(config as Partial<Config>);
const redisUrl = process.env.REDIS_URL || 'redis://localhost:6379';
const redisClient = createClient({ url: redisUrl });

// const runningPromises: (string | undefined)[] = [];
// let isRunning = false;
// const OldPromise = globalThis.Promise; 
// globalThis.Promise = class Promise<T> extends OldPromise<T> {
//   constructor(executor: (resolve: (value: T | PromiseLike<T>) => void, reject: (reason?: any) => void) => void) {
//     super(executor); // call native Promise constructor
//     if (!isRunning) {
//       isRunning = true;
//       const stack = new Error().stack;
//       runningPromises.push(stack);
//       this.then(() => {
//         const index = runningPromises.indexOf(stack);
//         runningPromises.splice(index, 1);
//       });
//       isRunning = false;
//     }
//   }
// };

beforeAll(async () => {
  await redisClient.connect();
  await app.ready();
  await app.listen({ port: 0 });
});

afterAll(async () => {
  console.log("Closing app");
  await app.close();
  console.log("Closed app");
  await redisClient.close();
  console.log("Closed redis");
}, 20000);

const sendRedisValue = async (redisRequestId: string, key: string, value: string) => {
  await redisClient.xAdd(`stream:${redisRequestId}`, '*', { [`:${key}`]: JSON.stringify(value) });
};

const sendRedisItemValue = async (redisRequestId: string, itemIndex: number, value: string) => {
  await sendRedisValue(redisRequestId, `Item${itemIndex}`, value);
};

const extractHtmlFromChunks = (chunks: string) => {
  chunks.split("\n").map(chunk => chunk.trim().length > 0 ? JSON.parse(chunk).html : chunk).join("");
}

const createParallelRenders = (size: number) => {
  const redisRequestIds = Array(size).fill(null).map(() => randomUUID());
  const renderRequests = redisRequestIds.map(redisRequestId => {
    return makeRequest(app, {
      componentName: 'RedisReceiver',
      props: { requestId: redisRequestId },
    });
  });

  const expectNextChunk = async (expectedNextChunk: string) => {
    const nextChunks = await Promise.all(renderRequests.map(renderRequest => renderRequest.waitForNextChunk()));
    nextChunks.forEach((chunk, index) => {
      const redisRequestId = redisRequestIds[index]!;
      console.log("Asserting Chunk")
      expect(extractHtmlFromChunks(chunk.replace(new RegExp(redisRequestId, 'g'), '')))
        .toEqual(extractHtmlFromChunks(expectedNextChunk));
    });
  }

  const sendRedisItemValues = async (itemIndex: number, itemValue: string) => {
    await Promise.all(redisRequestIds.map(redisRequestId => sendRedisItemValue(redisRequestId, itemIndex, itemValue)));
  }

  const waitUntilFinished = async () => {
    await Promise.all(renderRequests.map(renderRequest => renderRequest.finishedPromise));
    renderRequests.forEach(renderRequest => expect(renderRequest.getBuffer()).toHaveLength(0));
  }

  return {
    expectNextChunk,
    sendRedisItemValues,
    waitUntilFinished,
  }
}

test('Happy Path', async () => {
  const parallelInstances = 20;
  expect.assertions(parallelInstances*7 + 7);
  const redisRequestId = randomUUID();
  const { waitForNextChunk, finishedPromise, getBuffer } = makeRequest(app, {
    componentName: 'RedisReceiver',
    props: { requestId: redisRequestId },
  });
  const chunks: string[] = [];
  let chunk = await waitForNextChunk();
  expect(chunk).not.toContain('Unique Value');
  chunks.push(chunk.replace(new RegExp(redisRequestId, 'g'), ''));

  sendRedisItemValue(redisRequestId, 0, 'First Unique Value');
  chunk = await waitForNextChunk();
  expect(chunk).toContain('First Unique Value');
  chunks.push(chunk.replace(new RegExp(redisRequestId, 'g'), ''));

  sendRedisItemValue(redisRequestId, 4, 'Fifth Unique Value');
  chunk = await waitForNextChunk();
  expect(chunk).toContain('Fifth Unique Value');
  chunks.push(chunk.replace(new RegExp(redisRequestId, 'g'), ''));

  sendRedisItemValue(redisRequestId, 2, 'Third Unique Value');
  chunk = await waitForNextChunk();
  expect(chunk).toContain('Third Unique Value');
  chunks.push(chunk.replace(new RegExp(redisRequestId, 'g'), ''));

  sendRedisItemValue(redisRequestId, 1, 'Second Unique Value');
  chunk = await waitForNextChunk();
  expect(chunk).toContain('Second Unique Value');
  chunks.push(chunk.replace(new RegExp(redisRequestId, 'g'), ''));

  sendRedisItemValue(redisRequestId, 3, 'Forth Unique Value');
  chunk = await waitForNextChunk();
  expect(chunk).toContain('Forth Unique Value');
  chunks.push(chunk.replace(new RegExp(redisRequestId, 'g'), ''));

  await finishedPromise;
  expect(getBuffer).toHaveLength(0);

  const { expectNextChunk, sendRedisItemValues, waitUntilFinished } = createParallelRenders(parallelInstances);
  await expectNextChunk(chunks[0]!);
  sendRedisItemValues(0, 'First Unique Value');
  await expectNextChunk(chunks[1]!);
  sendRedisItemValues(4, 'Fifth Unique Value');
  await expectNextChunk(chunks[2]!);
  sendRedisItemValues(2, 'Third Unique Value');
  await expectNextChunk(chunks[3]!);
  sendRedisItemValues(1, 'Second Unique Value');
  await expectNextChunk(chunks[4]!);
  sendRedisItemValues(3, 'Forth Unique Value');
  await expectNextChunk(chunks[5]!);
  await waitUntilFinished();
}, 20000);
