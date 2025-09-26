import ReactOnRails from '../../packages/react-on-rails/src/ReactOnRails.client.ts';

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
});
