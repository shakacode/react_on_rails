const sharedMock = jest.fn();

describe('Jest base config clearMocks', () => {
  it('records calls and sets a mock implementation in one test', () => {
    sharedMock.mockReturnValue('first');
    expect(sharedMock()).toBe('first');
    expect(sharedMock).toHaveBeenCalledTimes(1);
  });

  it('clears call history before the next test', () => {
    expect(sharedMock).not.toHaveBeenCalled();
  });

  it('preserves mock implementations across tests', () => {
    // Intentional cross-test dependency: the previous test only clears calls.
    // This verifies clearMocks keeps the implementation set in the first test.
    expect(sharedMock()).toBe('first');
    expect(sharedMock).toHaveBeenCalledTimes(1);
  });
});
