import { assertRailsContextWithServerStreamingCapabilities } from '../src/types/index.ts';

// Builds a railsContext that satisfies RailsContextWithServerComponentMetadata plus the two
// pre-existing streaming capabilities. `recordRSCDiagnostic` is omitted by default so tests can
// opt into the additive (#3475) field explicitly.
const buildStreamingContext = (overrides: Record<string, unknown> = {}) => ({
  serverSide: true,
  reactClientManifestFileName: 'clientManifest.json',
  reactServerClientManifestFileName: 'serverClientManifest.json',
  getRSCPayloadStream: () => Promise.resolve({} as NodeJS.ReadableStream),
  addPostSSRHook: () => {},
  ...overrides,
});

describe('assertRailsContextWithServerStreamingCapabilities', () => {
  it('passes when the two pre-existing capabilities are present, even without recordRSCDiagnostic', () => {
    // Backward compatibility (#3475): an external consumer built against an older Pro version supplies
    // getRSCPayloadStream + addPostSSRHook but not the additive recordRSCDiagnostic. This must NOT throw.
    const context = buildStreamingContext();
    expect(() => assertRailsContextWithServerStreamingCapabilities(context as never)).not.toThrow();
  });

  it('passes when recordRSCDiagnostic is also present', () => {
    const context = buildStreamingContext({ recordRSCDiagnostic: () => {} });
    expect(() => assertRailsContextWithServerStreamingCapabilities(context as never)).not.toThrow();
  });

  it('throws when a pre-existing required capability (getRSCPayloadStream) is missing', () => {
    const context = buildStreamingContext({ getRSCPayloadStream: undefined });
    expect(() => assertRailsContextWithServerStreamingCapabilities(context as never)).toThrow(
      /getRSCPayloadStream and addPostSSRHook/,
    );
  });

  it('throws when a pre-existing required capability (addPostSSRHook) is missing', () => {
    const context = buildStreamingContext({ addPostSSRHook: undefined });
    expect(() => assertRailsContextWithServerStreamingCapabilities(context as never)).toThrow(
      /getRSCPayloadStream and addPostSSRHook/,
    );
  });
});
