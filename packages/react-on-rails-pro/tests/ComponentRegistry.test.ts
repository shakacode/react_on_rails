import type { RegisteredComponentValue } from 'react-on-rails/types';
import * as ComponentRegistry from '../src/ComponentRegistry.ts';

type Assert<T extends true> = T;

type GetComponentValue = ReturnType<typeof ComponentRegistry.get>['component'];
type GetOrWaitComponentValue = Awaited<
  ReturnType<typeof ComponentRegistry.getOrWaitForComponent>
>['component'];
type ComponentsMapValue =
  ReturnType<typeof ComponentRegistry.components> extends Map<string, { component: infer ComponentValue }>
    ? ComponentValue
    : never;

type _GetReturnsRegisteredComponentValue = Assert<
  RegisteredComponentValue extends GetComponentValue ? true : false
>;
type _GetOrWaitReturnsRegisteredComponentValue = Assert<
  RegisteredComponentValue extends GetOrWaitComponentValue ? true : false
>;
type _ComponentsReturnsRegisteredComponentValue = Assert<
  RegisteredComponentValue extends ComponentsMapValue ? true : false
>;

describe('ComponentRegistry', () => {
  afterEach(() => {
    ComponentRegistry.clear();
  });

  it('registers and retrieves plain object modules without treating them as render functions', () => {
    const plainObjectModule = { metadata: 'server_render_js payload' };

    ComponentRegistry.register({ PlainObjectModule: plainObjectModule });

    expect(ComponentRegistry.get('PlainObjectModule')).toEqual({
      name: 'PlainObjectModule',
      component: plainObjectModule,
      renderFunction: false,
      isRenderer: false,
    });
  });
});
