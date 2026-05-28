/**
 * @jest-environment node
 */

import { text } from 'stream/consumers';
import { Readable } from 'stream';

import transformRSCStream from '../src/transformRSCNodeStream.ts';
import { buildRSCStreamDiagnosticError, mergeRSCStreamDiagnosticError } from '../src/rscDiagnostics.ts';

const encodeLengthPrefixedChunk = (metadata: Record<string, unknown>, content: string) => {
  const contentBuffer = Buffer.from(content, 'utf-8');
  return `${JSON.stringify(metadata)}\t${contentBuffer.length.toString(16).padStart(8, '0')}\n${content}`;
};

describe('RSC diagnostics', () => {
  it('reports RSC bundle rendering errors from stream metadata while preserving Flight bytes', async () => {
    const diagnosticStack =
      'TypeError: useState is not a function\n' +
      '    at CommentsToggle (/app/components/CommentsToggle.jsx:12:15)\n' +
      '    at PostsPage (/app/components/PostsPage.jsx:8:3)';
    const source = Readable.from([
      encodeLengthPrefixedChunk(
        {
          consoleReplayScript: '',
          hasErrors: true,
          isShellReady: true,
          payloadType: 'string',
          renderingError: {
            message: 'useState is not a function',
            stack: diagnosticStack,
          },
        },
        '0:"$L1"\n',
      ),
    ]);
    const onDiagnosticError = jest.fn();

    const transformedStream = transformRSCStream(source, {
      componentName: 'CommentsToggle',
      onDiagnosticError,
    });

    await expect(text(transformedStream)).resolves.toBe('0:"$L1"\n');
    expect(onDiagnosticError).toHaveBeenCalledTimes(1);

    const diagnosticError = onDiagnosticError.mock.calls[0][0] as Error;
    expect(diagnosticError.name).toBe('ReactOnRailsRSCStreamError');
    expect(diagnosticError.message).toContain('RSC bundle rendering failed');
    expect(diagnosticError.message).toContain('Component: CommentsToggle');
    expect(diagnosticError.message).toContain('Original error: useState is not a function');
    expect(diagnosticError.message).toContain('Module: /app/components/CommentsToggle.jsx');
    expect(diagnosticError.stack).toContain(diagnosticStack);
  });

  it('merges a generic React stream failure with the original RSC bundle diagnostic', () => {
    const diagnosticError = new Error(
      '[ReactOnRails] RSC bundle rendering failed.\n' +
        'Component: CommentsToggle\n' +
        'Original error: useState is not a function',
    );
    diagnosticError.name = 'ReactOnRailsRSCStreamError';
    diagnosticError.stack = 'TypeError: useState is not a function\n    at CommentsToggle.jsx:12:15';
    const genericStreamError = new Error('An error occurred in the Server Components render.');

    const mergedError = mergeRSCStreamDiagnosticError(genericStreamError, diagnosticError);

    expect(mergedError.name).toBe('ReactOnRailsRSCStreamError');
    expect(mergedError.message).toContain('Original error: useState is not a function');
    expect(mergedError.message).toContain(
      'React stream error: An error occurred in the Server Components render.',
    );
    expect(mergedError.stack).toContain('CommentsToggle.jsx:12:15');
  });

  it('keeps diagnostic merges idempotent when a merged error reaches another catch handler', () => {
    const diagnosticError = new Error(
      '[ReactOnRails] RSC bundle rendering failed.\n' +
        'Component: CommentsToggle\n' +
        'Original error: useState is not a function',
    );
    diagnosticError.name = 'ReactOnRailsRSCStreamError';
    const genericStreamError = new Error('An error occurred in the Server Components render.');

    const mergedError = mergeRSCStreamDiagnosticError(genericStreamError, diagnosticError);
    const mergedAgainError = mergeRSCStreamDiagnosticError(mergedError, diagnosticError);

    expect(mergedAgainError).toBe(mergedError);
    expect(mergedAgainError.message.match(/Original error: useState is not a function/g)).toHaveLength(1);
    expect(
      mergedAgainError.message.match(
        /React stream error: An error occurred in the Server Components render\./g,
      ),
    ).toHaveLength(1);
  });

  it('emits the hasErrors=true fallback diagnostic when the stream provides no message or stack', () => {
    const diagnosticError = buildRSCStreamDiagnosticError(
      { hasErrors: true },
      { componentName: 'CommentsToggle', source: '/rsc/CommentsToggle' },
    );

    expect(diagnosticError).toBeDefined();
    expect(diagnosticError?.message).toContain('Component: CommentsToggle');
    expect(diagnosticError?.message).toContain('Source: /rsc/CommentsToggle');
    expect(diagnosticError?.message).toContain('Original error: RSC stream metadata reported hasErrors=true');
  });

  it('treats a merged diagnostic as idempotent even when the message format changes', () => {
    const diagnosticError = new Error('[ReactOnRails] RSC bundle rendering failed.');
    diagnosticError.name = 'ReactOnRailsRSCStreamError';
    const genericStreamError = new Error('boom');

    const mergedError = mergeRSCStreamDiagnosticError(genericStreamError, diagnosticError);

    // Tampering with the merged error's message should still leave it recognized as merged
    // because the guard is now structural (flag property), not message-text based.
    mergedError.message = 'unrelated message';
    const mergedAgainError = mergeRSCStreamDiagnosticError(mergedError, diagnosticError);

    expect(mergedAgainError).toBe(mergedError);
  });
});
