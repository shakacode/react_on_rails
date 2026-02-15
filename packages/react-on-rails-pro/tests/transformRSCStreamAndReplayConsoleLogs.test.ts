import transformRSCStreamAndReplayConsoleLogs from '../src/transformRSCStreamAndReplayConsoleLogs.ts';

const createPayloadStream = (line: string) => {
  const encoder = new TextEncoder();
  return new ReadableStream<Uint8Array>({
    start(controller) {
      controller.enqueue(encoder.encode(line));
      controller.close();
    },
  });
};

const collectStream = async (stream: ReadableStream<Uint8Array>) => {
  const reader = stream.getReader();
  const decoder = new TextDecoder();
  let result = '';

  while (true) {
    // eslint-disable-next-line no-await-in-loop
    const { done, value } = await reader.read();
    if (done) {
      break;
    }

    result += decoder.decode(value, { stream: true });
  }

  return result;
};

describe('transformRSCStreamAndReplayConsoleLogs', () => {
  beforeEach(() => {
    document.body.innerHTML = '';
  });

  it('adds nonce to replayed console scripts', async () => {
    const payloadLine =
      `${JSON.stringify({ html: '<div>Hello</div>', consoleReplayScript: '<script>console.log("x")</script>' })}\n`;
    const stream = createPayloadStream(payloadLine);

    const transformedStream = transformRSCStreamAndReplayConsoleLogs(stream, 'abc123');
    const html = await collectStream(transformedStream);

    expect(html).toBe('<div>Hello</div>');
    const script = document.body.querySelector('script');
    expect(script).not.toBeNull();
    expect(script?.getAttribute('nonce')).toBe('abc123');
    expect(script?.textContent).toContain('console.log("x")');
  });

  it('sanitizes nonce before assigning to replayed scripts', async () => {
    const payloadLine =
      `${JSON.stringify({ html: '<div>Hello</div>', consoleReplayScript: '<script>console.log("x")</script>' })}\n`;
    const stream = createPayloadStream(payloadLine);

    const transformedStream = transformRSCStreamAndReplayConsoleLogs(stream, 'abc123" onclick=alert(1)');
    await collectStream(transformedStream);

    const script = document.body.querySelector('script');
    expect(script?.getAttribute('nonce')).toBe('abc123onclickalert1');
    expect(script?.getAttribute('onclick')).toBeNull();
  });
});
