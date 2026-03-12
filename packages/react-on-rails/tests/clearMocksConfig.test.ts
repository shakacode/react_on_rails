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
    expect(sharedMock()).toBe('first');
    expect(sharedMock).toHaveBeenCalledTimes(1);
  });
});
