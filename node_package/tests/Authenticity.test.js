import ReactOnRails from '../src/ReactOnRails';

const testToken = 'TEST_CSRF_TOKEN';

const meta = document.createElement('meta');
meta.name = 'csrf-token';
meta.content = testToken;
document.head.appendChild(meta);

describe('authenticityToken', () => {
  expect.assertions(2);
  it('exists in ReactOnRails API', () => {
    expect.assertions(1);
    expect(typeof ReactOnRails.authenticityToken).toEqual('function');
  })

  it('can read Rails CSRF token from <meta>', () => {
    expect.assertions(1);
    const realToken = ReactOnRails.authenticityToken();
    expect(realToken).toEqual(testToken);
  })
})

describe('authenticityHeaders', () => {
  expect.assertions(2);
  it('exists in ReactOnRails API', () => {
    expect.assertions(1);
    expect(typeof ReactOnRails.authenticityHeaders).toEqual('function');
  })

  it('returns valid header with CSRF token', () => {
    expect.assertions(1);
    const realHeader = ReactOnRails.authenticityHeaders();
    expect(realHeader).toEqual({ 'X-CSRF-Token': testToken, 'X-Requested-With': 'XMLHttpRequest' });
  })
})
