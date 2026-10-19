/** @jest-environment node */

import { AsyncLocalStorage } from 'node:async_hooks';
import StoreRegistry from '../src/StoreRegistry.ts';
import type { Store } from '../src/types/index.ts';

test('getStore, stores and clearHydratedStores use the render scope while the page fallback stays intact', async () => {
  const storage = new AsyncLocalStorage<Map<object, unknown>>();
  Object.assign(globalThis, { reactOnRailsHydratedStoreScope: storage });
  const pageStore = { getState: () => ({ user: 'page' }) } as Store;
  StoreRegistry.setStore('UserStore', pageStore);
  try {
    const render = (user: string) =>
      storage.run(new Map(), async () => {
        const store = { getState: () => ({ user }) } as Store;
        StoreRegistry.setStore('UserStore', store);
        await Promise.resolve();
        expect(StoreRegistry.getStore('UserStore')).toBe(store);
        expect(StoreRegistry.stores().get('UserStore')).toBe(store);
        StoreRegistry.clearHydratedStores();
        expect(StoreRegistry.getStore('UserStore', false)).toBeUndefined();
        return store.getState();
      });
    await expect(Promise.all([render('Alice'), render('Bob')])).resolves.toEqual([
      { user: 'Alice' },
      { user: 'Bob' },
    ]);
    expect(StoreRegistry.getStore('UserStore')).toBe(pageStore);
  } finally {
    StoreRegistry.clearHydratedStores();
    Reflect.deleteProperty(globalThis, 'reactOnRailsHydratedStoreScope');
  }
});
