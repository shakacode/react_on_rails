import removeRSCChunkStack from './utils/removeRSCChunkStack.ts';

describe('removeRSCChunkStack', () => {
  it('returns processed string, not undefined', () => {
    const input = '{"html":"test content"}';
    const result = removeRSCChunkStack(input);

    // This test would fail if removeRSCChunkStack doesn't have a return statement
    // because result would be undefined instead of a string
    expect(result).toBeDefined();
    expect(typeof result).toBe('string');
  });

  it('handles empty input', () => {
    const result = removeRSCChunkStack('');
    expect(result).toBe('');
  });

  it('handles whitespace-only input', () => {
    const result = removeRSCChunkStack('   \n   ');
    expect(result).toBe('   \n   ');
  });

  it('preserves valid JSON structure', () => {
    const input = '{"html":"<div>Hello</div>"}';
    const result = removeRSCChunkStack(input);

    expect(result).toBeDefined();
    const parsed = JSON.parse(result);
    expect(parsed.html).toBeDefined();
  });

  it('handles multiline chunks', () => {
    const input = '{"html":"line1"}\n{"html":"line2"}';
    const result = removeRSCChunkStack(input);

    expect(result).toBeDefined();
    expect(result).toContain('line1');
    expect(result).toContain('line2');
  });
});
