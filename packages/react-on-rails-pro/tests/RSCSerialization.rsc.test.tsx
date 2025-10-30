/**
 * @jest-environment node
 */

import { PassThrough } from 'stream';
import { buildServerRenderer } from 'react-on-rails-rsc/server.node';
import { buildClientRenderer } from 'react-on-rails-rsc/client.node';

const emptyManifestObject = {
  filePathToModuleMetadata: {},
  moduleLoading: { prefix: '', crossOrigin: null },
};

const { renderToPipeableStream } = buildServerRenderer(emptyManifestObject);
const { createFromNodeStream } = buildClientRenderer(emptyManifestObject, emptyManifestObject);

test('renderToPipeableStream can encode objects into RSC stream', async () => {
  const encodedStream = renderToPipeableStream({
    name: 'Alice',
    age: 22,
  });
  const readableStream = new PassThrough();

  encodedStream.pipe(readableStream);
  const decodedObject = await createFromNodeStream(readableStream);
  expect(decodedObject).toMatchObject({
    name: 'Alice',
    age: 22,
  });
});

test('renderToPipeableStream can encode Error objects into RSC stream', async () => {
  const encodedStream = renderToPipeableStream(new Error('Fake Error'));
  const readableStream = new PassThrough();

  encodedStream.pipe(readableStream);
  const decodedObject = await createFromNodeStream(readableStream);
  expect(decodedObject).toBeInstanceOf(Error);
  expect(decodedObject).toEqual(
    expect.objectContaining({
      message: 'Fake Error',
    }),
  );
});
