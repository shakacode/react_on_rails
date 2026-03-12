// Intentionally shared across tests to validate clearMocks behavior on a persistent mock.
const sharedMock = jest.fn();

describe('Jest base config clearMocks', () => {
  beforeAll(() => {
    sharedMock.mockReturnValue('first');
  });

  it('records calls in one test', () => {
    expect(sharedMock()).toBe('first');
    expect(sharedMock).toHaveBeenCalledTimes(1);
  });

  it('clears call history before the next test', () => {
    expect(sharedMock).not.toHaveBeenCalled();
  });

  it('preserves mock implementations across tests', () => {
    expect(sharedMock.getMockImplementation()).toBeDefined();
    expect(sharedMock()).toBe('first');
    expect(sharedMock).toHaveBeenCalledTimes(1);
  });
});
