import { RSC_STREAM_DIAGNOSTIC_ERROR_NAME } from '../src/rscDiagnostics.ts';

const setDocumentReadyState = (readyState: DocumentReadyState) => {
  Object.defineProperty(document, 'readyState', {
    value: readyState,
    configurable: true,
    writable: true,
  });
};

describe('getReactServerComponent preloaded payload diagnostics', () => {
  beforeAll(() => {
    const webpackWindow = window as unknown as Window & {
      __webpack_chunk_load__: jest.Mock;
      __webpack_require__: jest.Mock;
    };

    webpackWindow.__webpack_require__ = jest.fn();
    webpackWindow.__webpack_chunk_load__ = jest.fn();
  });

  it('merges RSC diagnostics into preloaded hydration errors', async () => {
    expect.assertions(7);
    const { createFromPreloadedPayloads } = await import('../src/getReactServerComponent.client.ts');
    let diagnosticMetadata: Record<string, unknown> | undefined;
    const payloads: string[] = [];
    const originalReadyState = document.readyState;
    setDocumentReadyState('loading');

    const renderPromise = createFromPreloadedPayloads(payloads, 'TestComponent', () => diagnosticMetadata);
    diagnosticMetadata = {
      hasErrors: true,
      renderingError: {
        message: 'useState is not a function',
        stack:
          'TypeError: useState is not a function\n' +
          '    at HooksWithoutClientDirective (/app/components/HooksWithoutClientDirective.server.tsx:4:7)',
      },
    };
    payloads.push('not valid Flight data\n');
    setDocumentReadyState('complete');
    document.dispatchEvent(new Event('DOMContentLoaded'));

    try {
      await renderPromise;
    } catch (error) {
      const caughtError = error as Error;
      expect(caughtError).toBeInstanceOf(Error);
      expect(caughtError.name).toBe(RSC_STREAM_DIAGNOSTIC_ERROR_NAME);
      expect(caughtError.message).toContain('[ReactOnRails] RSC bundle rendering failed.');
      expect(caughtError.message).toContain('Component: TestComponent');
      expect(caughtError.message).toContain('Module: /app/components/HooksWithoutClientDirective.server.tsx');
      expect(caughtError.message).toContain('Original error: useState is not a function');
      expect(caughtError.message).toContain('React stream error: Failed to hydrate preloaded RSC payload');
    } finally {
      setDocumentReadyState(originalReadyState);
    }
  });

  it('wraps preloaded hydration errors without diagnostics when no metadata is available', async () => {
    expect.assertions(5);
    const { createFromPreloadedPayloads } = await import('../src/getReactServerComponent.client.ts');
    const payloads: string[] = [];
    const originalReadyState = document.readyState;
    setDocumentReadyState('loading');

    const renderPromise = createFromPreloadedPayloads(payloads, 'TestComponent');
    payloads.push('not valid Flight data\n');
    setDocumentReadyState('complete');
    document.dispatchEvent(new Event('DOMContentLoaded'));

    try {
      await renderPromise;
    } catch (error) {
      const caughtError = error as Error;
      expect(caughtError).toBeInstanceOf(Error);
      expect(caughtError.name).toBe('Error');
      expect(caughtError.name).not.toBe(RSC_STREAM_DIAGNOSTIC_ERROR_NAME);
      expect(caughtError.message).toContain(
        'Failed to hydrate preloaded RSC payload for component "TestComponent"',
      );
      expect(caughtError.message).not.toContain('[ReactOnRails] RSC bundle rendering failed.');
    } finally {
      setDocumentReadyState(originalReadyState);
    }
  });
});
