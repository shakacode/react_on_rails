import AsyncPropsManager, { getOrCreateAsyncPropsManager } from '../src/AsyncPropsManager.ts';

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

/**
 * Tests for getOrCreateAsyncPropsManager - the lazy initialization factory function.
 *
 * These tests verify the race condition fix where update chunks might execute
 * before or during the initial render. The key invariant is that all callers
 * must get the SAME AsyncPropsManager instance from the shared execution context.
 */
describe('getOrCreateAsyncPropsManager lazy initialization', () => {
  let sharedExecutionContext: Map<string, unknown>;

  beforeEach(() => {
    sharedExecutionContext = new Map();
  });

  it('returns the same instance on repeated calls', () => {
    const manager1 = getOrCreateAsyncPropsManager(sharedExecutionContext);
    const manager2 = getOrCreateAsyncPropsManager(sharedExecutionContext);

    expect(manager1).toBe(manager2);
  });

  it('creates a new manager on first call', () => {
    expect(sharedExecutionContext.size).toBe(0);

    const manager = getOrCreateAsyncPropsManager(sharedExecutionContext);

    expect(manager).toBeInstanceOf(AsyncPropsManager);
    expect(sharedExecutionContext.size).toBe(1);
  });

  it('handles update chunks arriving BEFORE initial render (setProp then getProp)', async () => {
    // Simulate update chunk executing first (e.g., due to race condition)
    const managerFromUpdateChunk = getOrCreateAsyncPropsManager(sharedExecutionContext);
    managerFromUpdateChunk.setProp('users', ['Alice', 'Bob']);

    // Simulate initial render executing second
    const managerFromInitialRender = getOrCreateAsyncPropsManager(sharedExecutionContext);

    // Verify they're the same instance
    expect(managerFromUpdateChunk).toBe(managerFromInitialRender);

    // Verify prop was already set and accessible
    const result = await managerFromInitialRender.getProp('users');
    expect(result).toEqual(['Alice', 'Bob']);
  });

  it('handles update chunks arriving DURING initial render (interleaved operations)', async () => {
    // Initial render starts - creates manager and requests a prop
    const managerFromRender = getOrCreateAsyncPropsManager(sharedExecutionContext);
    const usersPromise = managerFromRender.getProp('users');
    const postsPromise = managerFromRender.getProp('posts');

    // Update chunk arrives - gets same manager and sets first prop
    const managerFromChunk1 = getOrCreateAsyncPropsManager(sharedExecutionContext);
    expect(managerFromChunk1).toBe(managerFromRender);
    managerFromChunk1.setProp('users', ['User1', 'User2']);

    // First prop resolves
    await expect(usersPromise).resolves.toEqual(['User1', 'User2']);

    // Another update chunk arrives - gets same manager and sets second prop
    const managerFromChunk2 = getOrCreateAsyncPropsManager(sharedExecutionContext);
    expect(managerFromChunk2).toBe(managerFromRender);
    managerFromChunk2.setProp('posts', ['Post1', 'Post2']);

    // Second prop resolves
    await expect(postsPromise).resolves.toEqual(['Post1', 'Post2']);
  });

  it('handles update chunks arriving AFTER initial render (getProp then setProp)', async () => {
    // Initial render executes first - creates manager and requests props
    const managerFromInitialRender = getOrCreateAsyncPropsManager(sharedExecutionContext);
    const dataPromise = managerFromInitialRender.getProp('data');

    // Update chunk executes second - gets same manager and sets prop
    const managerFromUpdateChunk = getOrCreateAsyncPropsManager(sharedExecutionContext);
    expect(managerFromUpdateChunk).toBe(managerFromInitialRender);
    managerFromUpdateChunk.setProp('data', { value: 42 });

    // Verify prop resolves correctly
    await expect(dataPromise).resolves.toEqual({ value: 42 });
  });

  it('isolates managers between different execution contexts', () => {
    const context1 = new Map<string, unknown>();
    const context2 = new Map<string, unknown>();

    const manager1 = getOrCreateAsyncPropsManager(context1);
    const manager2 = getOrCreateAsyncPropsManager(context2);

    // Different contexts should have different managers
    expect(manager1).not.toBe(manager2);
  });

  it('supports concurrent timing scenario - multiple props set before any getProp', async () => {
    // All update chunks arrive before initial render starts reading
    const manager = getOrCreateAsyncPropsManager(sharedExecutionContext);
    manager.setProp('prop1', 'value1');
    manager.setProp('prop2', 'value2');
    manager.setProp('prop3', 'value3');

    // Initial render starts and reads all props
    const sameManager = getOrCreateAsyncPropsManager(sharedExecutionContext);
    expect(sameManager).toBe(manager);

    // All props should be immediately available
    await expect(sameManager.getProp('prop1')).resolves.toBe('value1');
    await expect(sameManager.getProp('prop2')).resolves.toBe('value2');
    await expect(sameManager.getProp('prop3')).resolves.toBe('value3');
  });

  it('supports concurrent timing scenario - endStream called from update chunk context', async () => {
    // Initial render requests props
    const renderManager = getOrCreateAsyncPropsManager(sharedExecutionContext);
    const prop1Promise = renderManager.getProp('prop1');
    const prop2Promise = renderManager.getProp('prop2'); // This one won't be set

    // Update chunk sets one prop
    const chunkManager = getOrCreateAsyncPropsManager(sharedExecutionContext);
    chunkManager.setProp('prop1', 'received');

    // Another context calls endStream (simulating request close)
    const closeManager = getOrCreateAsyncPropsManager(sharedExecutionContext);
    expect(closeManager).toBe(renderManager);
    closeManager.endStream();

    // First prop should resolve, second should reject
    await expect(prop1Promise).resolves.toBe('received');
    await expect(prop2Promise).rejects.toThrow(/The async prop "prop2" is not received/);
  });
});
