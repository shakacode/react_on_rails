import ReactOnRails from '../src/ReactOnRails.client.ts';

const testToken = 'TEST_CSRF_TOKEN';

const meta = document.createElement('meta');
meta.name = 'csrf-token';
meta.content = testToken;
document.head.appendChild(meta);

describe('authenticityToken', () => {
  it('exists in ReactOnRails API', () => {
    expect(typeof ReactOnRails.authenticityToken).toBe('function');
  });

  it('can read Rails CSRF token from <meta>', () => {
    const realToken = ReactOnRails.authenticityToken();
    expect(realToken).toEqual(testToken);
  });
});

describe('authenticityHeaders', () => {
  it('exists in ReactOnRails API', () => {
    expect(typeof ReactOnRails.authenticityHeaders).toBe('function');
  });

  it('returns valid header with CSRF token', () => {
    const realHeader = ReactOnRails.authenticityHeaders();
    expect(realHeader).toEqual({ 'X-CSRF-Token': testToken, 'X-Requested-With': 'XMLHttpRequest' });
  });

  it('does not mutate the input object', () => {
    const input = { 'Content-Type': 'application/json' };
    ReactOnRails.authenticityHeaders(input);
    expect(input).toEqual({ 'Content-Type': 'application/json' });
  });

  it('returns a new object, not the same reference as the input', () => {
    const input = { 'Content-Type': 'application/json' };
    const result = ReactOnRails.authenticityHeaders(input);
    expect(result).not.toBe(input);
  });

  it('merges input headers with CSRF headers', () => {
    const input = { 'Content-Type': 'application/json' };
    const result = ReactOnRails.authenticityHeaders(input);
    expect(result).toEqual({
      'Content-Type': 'application/json',
      'X-CSRF-Token': testToken,
      'X-Requested-With': 'XMLHttpRequest',
    });
  });
});
