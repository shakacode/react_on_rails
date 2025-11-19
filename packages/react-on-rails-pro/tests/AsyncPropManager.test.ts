import AsyncPropsManager from '../src/AsyncPropsManager.ts';

describe('Access AsyncPropManager prop before setting it', () => {
  let manager: AsyncPropsManager;
  let getPropPromise: Promise<unknown>;

  beforeEach(() => {
    manager = new AsyncPropsManager();
    getPropPromise = manager.getProp('randomProp');
    manager.setProp('randomProp', 'Fake Value');
  });

  it('returns the same value', async () => {
    await expect(getPropPromise).resolves.toBe('Fake Value');
  });

  it('returns the same promise on success scenarios', async () => {
    const secondGetPropPromise = manager.getProp('randomProp');
    expect(secondGetPropPromise).toBe(getPropPromise);
    await expect(getPropPromise).resolves.toBe('Fake Value');
  });

  it('allows accessing multiple props', async () => {
    const getSecondPropPromise = manager.getProp('secondRandomProp');
    await expect(getPropPromise).resolves.toBe('Fake Value');
    manager.setProp('secondRandomProp', 'Another Fake Value');
    await expect(getSecondPropPromise).resolves.toBe('Another Fake Value');
  });
});

describe('Access AsyncPropManager prop after setting it', () => {
  let manager: AsyncPropsManager;
  let getPropPromise: Promise<unknown>;

  beforeEach(() => {
    manager = new AsyncPropsManager();
    manager.setProp('randomProp', 'Value got after setting');
    getPropPromise = manager.getProp('randomProp');
  });

  it('can set the prop before getting it', async () => {
    await expect(getPropPromise).resolves.toBe('Value got after setting');
  });

  it('returns the same promise on success scenarios', async () => {
    const secondGetPropPromise = manager.getProp('randomProp');
    expect(secondGetPropPromise).toBe(getPropPromise);
    await expect(getPropPromise).resolves.toBe('Value got after setting');
  });

  it('allows accessing multiple props', async () => {
    manager.setProp('secondRandomProp', 'Another Fake Value');
    const getSecondPropPromise = manager.getProp('secondRandomProp');
    await expect(getPropPromise).resolves.toBe('Value got after setting');
    await expect(getSecondPropPromise).resolves.toBe('Another Fake Value');
  });
});

describe('Access AsyncPropManager prop after closing the stream', () => {
  let manager: AsyncPropsManager;
  let getPropPromise: Promise<unknown>;

  beforeEach(() => {
    manager = new AsyncPropsManager();
    manager.setProp('prop accessed after closing', 'Value got after closing the stream');
    manager.endStream();
    getPropPromise = manager.getProp('prop accessed after closing');
  });

  it('can set the prop before getting it', async () => {
    await expect(getPropPromise).resolves.toBe('Value got after closing the stream');
  });

  it('returns the same promise on success scenarios', async () => {
    const secondGetPropPromise = manager.getProp('prop accessed after closing');
    expect(secondGetPropPromise).toBe(getPropPromise);
    await expect(getPropPromise).resolves.toBe('Value got after closing the stream');
  });
});

describe('Access non sent AsyncPropManager prop', () => {
  it('throws an error if non-existing prop is sent after closing the stream', async () => {
    const manager = new AsyncPropsManager();
    manager.endStream();
    await expect(manager.getProp('Non Existing Prop')).rejects.toThrow(
      /The async prop "Non Existing Prop" is not received/,
    );
  });

  it('rejects getPropPromise if the stream is closed before getting the prop value', async () => {
    const manager = new AsyncPropsManager();
    const getPropPromise = manager.getProp('wrongProp');
    manager.endStream();
    await expect(getPropPromise).rejects.toThrow(/The async prop "wrongProp" is not received/);
  });

  it('throws an error if a prop is set after closing the stream', () => {
    const manager = new AsyncPropsManager();
    manager.endStream();
    expect(() => manager.setProp('wrongProp', 'Nothing')).toThrow(
      /Can't set the async prop "wrongProp" because the stream is already closed/,
    );
  });
});

describe('Accessing AsyncPropManager prop in complex scenarios', () => {
  it('accepts multiple received props and reject multiple non sent props', async () => {
    const manager = new AsyncPropsManager();
    const accessBeforeSetPromise = manager.getProp('accessBeforeSetProp');
    const secondAccessBeforeSetPromise = manager.getProp('secondAccessBeforeSetProp');
    const nonExistingPropPromise = manager.getProp('nonExistingProp');

    // Setting and getting props
    manager.setProp('setBeforeAccessProp', 'Set Before Access Prop Value');
    manager.setProp('accessBeforeSetProp', 'Access Before Set Prop Value');
    await expect(accessBeforeSetPromise).resolves.toBe('Access Before Set Prop Value');
    await expect(manager.getProp('setBeforeAccessProp')).resolves.toBe('Set Before Access Prop Value');

    // Setting another prop
    manager.setProp('secondAccessBeforeSetProp', 'Second Access Before Set Prop Value');
    await expect(secondAccessBeforeSetPromise).resolves.toBe('Second Access Before Set Prop Value');

    // Ensure all props return the same promise
    expect(manager.getProp('accessBeforeSetProp')).toBe(manager.getProp('accessBeforeSetProp'));
    expect(manager.getProp('secondAccessBeforeSetProp')).toBe(manager.getProp('secondAccessBeforeSetProp'));
    expect(manager.getProp('setBeforeAccessProp')).toBe(manager.getProp('setBeforeAccessProp'));

    // Access props one more time
    await expect(manager.getProp('setBeforeAccessProp')).resolves.toBe('Set Before Access Prop Value');
    await expect(manager.getProp('accessBeforeSetProp')).resolves.toBe('Access Before Set Prop Value');

    // Non existing props
    manager.endStream();
    await expect(nonExistingPropPromise).rejects.toThrow(/The async prop "nonExistingProp" is not received/);
    await expect(manager.getProp('wrongProp')).rejects.toThrow(/The async prop "wrongProp" is not received/);

    // Setting after closing
    expect(() => manager.setProp('wrongProp', 'Nothing')).toThrow(
      /Can't set the async prop "wrongProp" because the stream is already closed/,
    );
  });
});
