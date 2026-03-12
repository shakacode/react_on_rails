const sharedMock = jest.fn();

describe('Jest base config clearMocks', () => {
  it('records calls in one test', () => {
    sharedMock('first');
    expect(sharedMock).toHaveBeenCalledTimes(1);
  });

  it('clears call history before the next test', () => {
    expect(sharedMock).not.toHaveBeenCalled();
  });
});
