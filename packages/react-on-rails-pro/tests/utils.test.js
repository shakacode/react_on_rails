import { enableFetchMocks } from 'jest-fetch-mock';

import { fetch } from '../src/utils.ts';
import { createNodeReadableStream, getNodeVersion } from './testUtils.ts';

enableFetchMocks();

// The fetch mock functionality that returns a ReadableStream is not supported in Node.js v16.
// Additionally, fetch function is used in RSCClientRoot only that is compatible with Node.js v18+,
// so these tests are conditionally skipped on older Node versions.
(getNodeVersion() >= 18 ? describe : describe.skip)('fetch', () => {
  it('streams body as ReadableStream', async () => {
    // create Readable stream that emits 5 chunks with 10ms delay between each chunk
    const { stream, push } = createNodeReadableStream();
    let n = 0;
    const intervalId = setInterval(() => {
      n += 1;
      push(`chunk${n}`);
      if (n === 5) {
        clearInterval(intervalId);
        push(null);
      }
    }, 10);

    global.fetchMock.mockResolvedValue(new Response(stream));

    await fetch('/test').then(async (response) => {
      console.log(response.body);
      const { body } = response;
      expect(body).toBeInstanceOf(ReadableStream);

      const reader = body.getReader();
      const chunks = [];
      const decoder = new TextDecoder();
      let { done, value } = await reader.read();
      while (!done) {
        chunks.push(decoder.decode(value));
        // eslint-disable-next-line no-await-in-loop
        ({ done, value } = await reader.read());
      }
      expect(chunks).toEqual(['chunk1', 'chunk2', 'chunk3', 'chunk4', 'chunk5']);

      // expect global.fetch to be called one time
      expect(global.fetch).toHaveBeenCalledTimes(1);
    });
  });
});
