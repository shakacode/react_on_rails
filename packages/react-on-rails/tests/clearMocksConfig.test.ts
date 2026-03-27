// Intentionally shared across tests to validate clearMocks behavior on a persistent mock.
// NOTE: This suite is order-dependent by design: each test verifies state after clearMocks
// runs between tests.
const sharedMock = jest.fn();

describe('Jest base config clearMocks', () => {
  beforeAll(() => {
    sharedMock.mockReturnValue('first');
  });

  it('records calls in one test', () => {
    expect(sharedMock()).toBe('first');
    expect(sharedMock).toHaveBeenCalledTimes(1);
  });

  it('does not retain call history from previous test', () => {
    expect(sharedMock).not.toHaveBeenCalled();
    sharedMock();
    expect(sharedMock).toHaveBeenCalledTimes(1);
  });

  it('preserves mock implementations across clear cycles', () => {
    // clearMocks does not call mockReset(), so the return value from beforeAll should persist.
    expect(sharedMock()).toBe('first');
    expect(sharedMock).toHaveBeenCalledTimes(1);
  });
});
